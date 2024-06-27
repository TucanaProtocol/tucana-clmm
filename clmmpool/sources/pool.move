// Copyright (c) Tucana Technology Limited

/// Concentrated Liquidity Market Maker (CLMM) is a new generation of automated market maker (AMM) aiming to improve
/// decentralized exchanges' capital efficiency and provide attractive yield opportunities for liquidity providers.
/// Different from the constant product market maker that only allows liquidity to be distributed uniformly across the
/// full price curve (0, `positive infinity`), CLMM allows liquidity providers to add their liquidity into specified price ranges.
/// The price in a CLMM pool is discrete, rather than continuous. The liquidity allocated into a specific price range
/// by a user is called a liquidity position.
///
/// "Pool" is the core module of Clmm protocol, which defines the trading pairs of "clmmpool".
/// All operations related to trading and liquidity are completed by this module.
module tucana_clmm::pool {
    use std::string::String;
    use initia_std::fungible_asset::{FungibleStore, Metadata, FungibleAsset};
    use initia_std::object::{ExtendRef, Object};
    use initia_std::simple_map::{SimpleMap};

    use tucana_std::i32::{I32};

    use tucana_clmm::tick::{Tick, TickManager};
    use tucana_clmm::partner::{Partner};
    use tucana_clmm::rewarder::{RewarderManager};
    use tucana_clmm::position::{PositionNftCollection, PositionNft};

    friend tucana_clmm::factory;

    /// The denominator of protocol fee rate(rate=protocol_fee_rate/10000)
    const PROTOCOL_FEE_DENOMINATOR: u64 = 10000;

    // =============== Errors =================

    const EAmountIncorrect: u64 = 0;
    const ELiquidityOverflow: u64 = 1;
    const ELiquidityIsZero: u64 = 2;
    const ENotEnoughLiquidity: u64 = 3;
    const ERemainderAmountUnderflow: u64 = 4;
    const ESwapAmountInOverflow: u64 = 5;
    const ESwapAmountOutOverflow: u64 = 6;
    const EFeeAmountOverflow: u64 = 7;
    const EInvalidFeeRate: u64 = 8;
    const ENotPositionOwner: u64 = 9;
    const EInvalidFixedCoinType: u64 = 10;
    const EWrongSqrtPriceLimit: u64 = 11;
    const EPoolIsPaused: u64 = 12;
    const EPoolIsNotPaused: u64 = 13;
    const EInvalidPartnerRefFeeRate: u64 = 14;
    const EAmountOutIsZero: u64 = 15;
    const EIncorrectOfferCoin: u64 = 16;
    const EAmountNeedAboveMaxLimit: u64 = 17;

    // =============== Structs =================

    /// The clmmpool
    struct Pool has key {
        extend_ref: ExtendRef,

        coin_a_store: Object<FungibleStore>,
        coin_b_store: Object<FungibleStore>,

        /// The tick spacing
        tick_spacing: u32,

        /// The numerator of fee rate, the denominator is 1_000_000.
        fee_rate: u64,

        /// The liquidity of current tick index
        liquidity: u128,

        /// The current sqrt price
        current_sqrt_price: u128,

        /// The current tick index
        current_tick_index: I32,

        /// The global fee growth of coin a,b as Q64.64
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,

        /// The amounts of coin a,b owned to protocol
        fee_protocol_coin_a: u64,
        fee_protocol_coin_b: u64,

        /// The tick manager
        tick_manager: TickManager,

        /// The rewarder manager
        rewarder_manager: RewarderManager,

        /// The position collection
        position_collection: Object<PositionNftCollection>,

        /// is the pool pause
        is_pause: bool,
    }

    /// The swap result
    struct SwapResult has copy, drop {
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        ref_fee_amount: u64,
        steps: u64,
    }

    /// Flash loan resource for add_liquidity
    struct AddLiquidityReceipt {
        pool_addr: address,
        amount_a: u64,
        amount_b: u64
    }

    /// Flash loan resource for swap.
    /// There is no way in Move to pass calldata and make dynamic calls, but a resource can be used for this purpose.
    /// To make the execution into a single transaction, the flash loan function must return a resource
    /// that cannot be copied, cannot be saved, cannot be dropped, or cloned.
    struct FlashSwapReceipt {
        pool_addr: address,
        memadata: Object<Metadata>,
        partner_addr: address,
        pay_amount: u64,
        ref_fee_amount: u64
    }

    /// The calculated swap result
    struct CalculatedSwapResult has copy, drop, store {
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        fee_rate: u64,
        after_sqrt_price: u128,
        current_sqrt_price: u128,
        is_exceed: bool,
        step_results: vector<SwapStepResult>
    }

    /// The step swap result
    struct SwapStepResult has copy, drop, store {
        current_sqrt_price: u128,
        target_sqrt_price: u128,
        current_liquidity: u128,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        remainder_amount: u64
    }

    // ============= Events =================

    #[event]
    /// Emited when a position was opened.
    struct OpenPositionEvent has copy, drop, store {
        pool_addr: address,
        tick_lower: I32,
        tick_upper: I32,
        position_addr: address,
    }

    #[event]
    /// Emited when a position was closed.
    struct ClosePositionEvent has copy, drop, store {
        pool_addr: address,
        position_addr: address,
    }

    #[event]
    /// Emited when add liquidity for a position.
    struct AddLiquidityEvent has copy, drop, store {
        pool_addr: address,
        position_addr: address,
        tick_lower: I32,
        tick_upper: I32,
        liquidity: u128,
        after_liquidity: u128,
        amount_a: u64,
        amount_b: u64,
    }

    #[event]
    /// Emited when remove liquidity from a position.
    struct RemoveLiquidityEvent has copy, drop, store {
        pool_addr: address,
        position_addr: address,
        tick_lower: I32,
        tick_upper: I32,
        liquidity: u128,
        after_liquidity: u128,
        amount_a: u64,
        amount_b: u64,
    }

    #[event]
    /// Emited when swap in a clmmpool.
    struct SwapEvent has copy, drop, store {
        atob: bool,
        pool_addr: address,
        partner_addr: address,
        amount_in: u64,
        amount_out: u64,
        ref_amount: u64,
        fee_amount: u64,
        vault_a_amount: u64,
        vault_b_amount: u64,
        before_sqrt_price: u128,
        after_sqrt_price: u128,
        steps: u64,
    }

    #[event]
    /// Emited when the protocol manager collect protocol fee from clmmpool.
    struct CollectProtocolFeeEvent has copy, drop, store {
        pool_addr: address,
        amount_a: u64,
        amount_b: u64
    }

    #[event]
    /// Emited when user collect liquidity fee from a position.
    struct CollectFeeEvent has copy, drop, store {
        position_addr: address,
        pool_addr: address,
        amount_a: u64,
        amount_b: u64
    }

    #[event]
    /// Emited when the clmmpool's liqudity fee rate updated.
    struct UpdateFeeRateEvent has copy, drop, store {
        pool_addr: address,
        old_fee_rate: u64,
        new_fee_rate: u64
    }

    #[event]
    /// Emited when the rewarder's emission per second updated.
    struct UpdateEmissionEvent has copy, drop, store {
        pool_addr: address,
        reward_metadata: Object<Metadata>,
        emissions_per_second: u128,
    }

    #[event]
    /// Emited when a rewarder append to clmmpool.
    struct AddRewarderEvent has copy, drop, store {
        pool_addr: address,
        reward_metadata: Object<Metadata>,
    }

    #[event]
    /// Emited when collect reward from clmmpool's rewarder.
    struct CollectRewardEvent has copy, drop, store {
        position_addr: address,
        pool_addr: address,
        reward_amounts: SimpleMap<Object<Metadata>, u64>,
    }

    #[event]
    /// Emit when update the position uri
    struct UpdatePositionUriEvent has copy, drop, store {
        pool_addr: address,
        uri: String
    }

    #[event]
    /// Emit when pause the pool
    struct PausePoolEvent has copy, drop, store {
        pool_addr: address,
        manager: address
    }

    #[event]
    /// Emit when unpause the pool
    struct UnpausePoolEvent has copy, drop, store {
        pool_addr: address,
        manager: address
    }

    #[view]
    public fun pool_seed(
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32
    ): address {
        abort 0
    }

    /// Create a new pool, it only allow call by factory module.
    /// params
    ///     - metadata_a: Object<Metadata>
    ///     - metadata_b: Object<Metadata>
    ///     - `tick_spacing` We use tick to represent a discrete set of prices, and tick_spacing controls
    /// the density of the discrete price points.
    ///     - `init_sqrt_price` The clmmpool's initialize sqrt price. To facilitate calculation,
    /// clmmpool stores the square root of prices. Can I assist you with anything else?
    ///     - `fee_rate` The clmmpool's fee rate. Actually, the numerator of the fee rate is expressed in units,
    /// while the denominator is always 1,000,000. For example, 1000 represents 0.1% or 1000/1000000.
    ///     - position_uri
    public(friend) fun new(
        _creator: &signer,
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32,
        _init_sqrt_price: u128,
        _fee_rate: u64,
        _position_uri: String
    ): Object<Pool> {
        abort 0
    }


    /// Open a position
    ///
    /// params
    ///     - `pool` The clmmpool object.
    ///     - `tick_lower` The lower tick index of position. In Move, there is no native signed type,
    /// so `clmm` uses a custom `I32` type to represent 32-bit signed integers. It adopts a general implementation,
    /// where positive numbers store their original code, and negative numbers store their complement code.
    /// For ease of use, the input here is of `u32` type, so if the tick is negative, you should pass in its
    /// complement code.
    ///     - `tick_upper` The upper tick index of position.
    /// return
    ///     The position NFT
    public fun open_position(
        _account: &signer,
        _pool: Object<Pool>,
        _tick_lower: u32,
        _tick_upper: u32,
    ): Object<PositionNft>  {
        abort 0
    }

    /// Add liquidity on a position by fix liquidity amount.
    /// params
    ///     - `position_nft`  "clmm" uses NFTs to hold positions, which we call "position_nft".
    /// It serves as the unique authority representing the position. If you transfer it to another address,
    /// it means that you have also transferred the position to that address.
    ///     - `detal_liquidity` The liquidity amount which you want to add.
    /// return
    ///     AddLiquidityReceipt
    public fun add_liquidity(
        _position_nft: Object<PositionNft>,
        _delta_liquidity: u128,
    ): AddLiquidityReceipt  {
        abort 0
    }

    /// Add liquidity on a position by fix coin amount.
    /// params
    ///     - `position_nft` The positon nft object.
    ///     - `amount` The coin amount which you want to add to position. the coin type specify by `fix_amount_a`.
    ///     - `fix_amount_a` Which coin type you want fix amount to add into this position specify by this flag.
    /// return
    ///     AddLiquidityReceipt
    public fun add_liquidity_fix_coin(
        _position_nft: Object<PositionNft>,
        _amount: u64,
        _fix_amount_a: bool,
    ): AddLiquidityReceipt  {
        abort 0
    }

    public fun add_liquidity_pay_amount(
        _receipt: &AddLiquidityReceipt
    ): (u64, u64) {
        abort 0
    }

    /// Repay add liquidity for the position.
    /// Parans
    ///     - `receipt` A flash loan resource that can only delete by this function.
    ///     - `offer_coin_a`
    ///     - `offer_coin_b`
    public fun repay_add_liquidity(
        _receipt: AddLiquidityReceipt,
        _offer_coin_a: FungibleAsset,
        _offer_coin_b: FungibleAsset,
    )  {
        abort 0
    }

    /// Remove liquidity from a position.
    /// Params
    ///     - position_nft: Object<PositionNft>
    ///     - `delta_liquidity` The amount of liquidity will be remove.
    /// Return
    ///     the assets
    public fun remove_liquidity(
        _account: &signer,
        _position_nft: Object<PositionNft>,
        _delta_liquidity: u128,
    ): (FungibleAsset, FungibleAsset)  {
        abort 0
    }

    /// Close the position.
    /// This operation will burn the `position_nft`, so before calling it, you need to take away all
    /// assets(coin_a,coin_b,rewards) related to this `position`, otherwise it will fail.
    /// Params
    ///     - `position` The position's NFT
    /// Return
    ///     Null
    public fun close_position(
        _account: &signer,
        _position_nft: Object<PositionNft>,
    )  {
        abort 0
    }


    /// Collect the fee from position.
    /// Params
    ///     - `position_nft` The position's NFT.
    ///     - `recalcuate` There are multiple scenarios where, for example, `add_liquidity`/`remove_liquidity`
    /// will settle fees. If `collect_fee` and these operations are in the same transaction, and `collect_fee`
    /// comes after them, then recalculating will not have any impact on the result. In this case, `recalculate`
    /// can be set to `false` to save gas.
    ///
    /// Returns:
    ///     the return assets
    public fun collect_fee(
        _account: &signer,
        _position_nft: Object<PositionNft>,
        _recalculate: bool,
    ): (FungibleAsset, FungibleAsset)  {
        abort 0
    }

    /// Collect rewarder from position.
    /// Params
    ///    - `position_nft` The position's NFT.
    /// Returns:
    ///   the return asssets
    public fun collect_rewards(
        _account: &signer,
        _position_nft: Object<PositionNft>,
    ): vector<FungibleAsset>  {
        abort 0
    }

    /// Flash swap
    /// Params
    ///     - `pool` The clmm pool object.
    ///     - `a2b` One flag, if true, indicates that coin of MetadataA is exchanged with the coin of MetadataB.
    /// otherwise it indicates that the coin of MetadataB is exchanged with the coin of MetadataA.
    ///     - `by_amount_in` A flag, if set to true, indicates that the next `amount` parameter specifies
    /// the input amount, otherwise it specifies the output amount.
    ///     - `amount` The amount that indicates input or output.
    ///     - `sqrt_price_limit` Price limit, if the swap causes the price to it value, the swap will stop here and return
    public fun flash_swap(
        _pool: Object<Pool>,
        _a2b: bool,
        _by_amount_in: bool,
        _amount: u64,
        _sqrt_price_limit: u128,
    ): (FungibleAsset, FlashSwapReceipt)  {
        abort 0
    }

    /// Flash swap with partner, like flash swap but there has a partner object for receive ref fee.
    public fun flash_swap_with_partner(
        _pool: Object<Pool>,
        _partner: Object<Partner>,
        _a2b: bool,
        _by_amount_in: bool,
        _amount: u64,
        _sqrt_price_limit: u128,
    ): (FungibleAsset, FlashSwapReceipt)  {
        abort 0
    }

    /// Repay for flash swap with partner for receive ref fee.
    public fun repay_flash_swap(
        _receipt: FlashSwapReceipt,
        _offer_coin: FungibleAsset,
    )  {
        abort 0
    }


    /// Collect the protocol fee
    /// Params
    ///     - `pool` The clmm pool object.
    /// Returns
    ///     the return asssets
    public fun collect_protocol_fee(
        _manager: &signer,
        _pool: Object<Pool>,
    ): (FungibleAsset, FungibleAsset)  {
        abort 0
    }

    /// Initialize a `Rewarder` or metadata into `Pool` .
    /// Params
    ///     - `pool` The clmm pool object
    ///     - metadata: Object<Metadata>
    ///     - emission_per_second
    ///     - end_time
    /// Returns
    ///     Null
    public fun initialize_rewarder(
        _manager: &signer,
        _pool: Object<Pool>,
        _metadata: Object<Metadata>,
        _emission_per_second: u128,
        _end_time: u64
    )  {
        abort 0
    }

    /// Update the rewarder emission speed to start the rewarder to generate.
    /// Params
    ///     - `pool` The clmm pool object
    ///     - `emissions_per_second` The parameter represents the number of rewards released per second,
    /// which is a fixed-point number with a total of 128 bits, with the decimal part occupying 64 bits.
    /// If a value of 0 is passed in, it indicates that the Rewarder's reward release will be paused.
    ///     - end_time
    /// Returns
    ///     Null
    public fun update_emission(
        _manager: &signer,
        _pool: Object<Pool>,
        _metadata: Object<Metadata>,
        _emissions_per_second: u128,
        _end_time: u64
    )  {
        abort 0
    }

    /// Update the position nft image uri. Just take effect on the new position
    /// Params
    ///     - `pool` The clmm pool object
    ///     - `uri` The new position nft image uri
    /// Returns
    ///     Null
    public fun update_position_uri(
        _manager: &signer,
        _pool: Object<Pool>,
        _uri: String,
    )  {
        abort 0
    }

    /// Update pool fee rate
    /// Params
    ///     - `pool` The clmm pool object
    ///     - `fee_rate` The pool new fee rate
    /// Returns
    ///     Null
    public fun update_fee_rate(
        _manager: &signer,
        _pool: Object<Pool>,
        _fee_rate: u64,
    )  {
        abort 0
    }

    /// Pause the pool.
    /// For special cases, `pause` is used to pause the `Pool`. When a `Pool` is paused, all operations except for
    /// `unpause` are disabled.
    /// Params
    ///     - `pool` The clmm pool object
    /// Returns
    ///     Null
    public fun pause(
        _manager: &signer,
        _pool: Object<Pool>,
    )  {
        abort 0
    }

    /// Unpause the pool.
    /// Params
    ///     - `pool` The clmm pool object
    /// Returns
    ///     Null
    public fun unpause(
        _manager: &signer,
        _pool: Object<Pool>,
    )  {
        abort 0
    } 

    public fun get_rewards_in_tick_range(
        _pool: &Pool,
        _tick_lower_index: I32,
        _tick_upper_index: I32,
    ): vector<u128> {
        abort 0
    }

    public fun get_fee_rewards_in_tick_range(
        _pool: &Pool,
        _tick_lower_index: I32,
        _tick_upper_index: I32,
    ): (u128, u128, vector<u128>) {
        abort 0
    }

    #[view]
    /// Calculate the position's amount_a/amount_b
    /// Params
    ///     - `position_id` The object id of position's NFT.
    /// Returns
    ///     - `amount_a`
    ///     - `amount_b`
    public fun get_position_amounts(
        _position_nft: Object<PositionNft>,
    ): (u64, u64)  {
        abort 0
    }

    #[view]
    /// Calculate the position's fee and return it.
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `position_id` The object id of position's NFT.
    /// Returns
    ///     - `fee_a` The fee amount of `CoinTypeA`
    ///     - `fee_b` The fee amount of `CoinTypeB`
    public fun calculate_fee(
        _position_nft: Object<PositionNft>,
    ): (u64, u64)  {
        abort 0
    }

    #[view]
    public fun calculate_rewards(
        _position_nft: Object<PositionNft>,
    ): vector<u64>  {
        abort 0
    }

    #[view]
    /// Calculate the swap result.
    /// It is used to perform pre-calculation on swap and does not modify any data.
    /// Params
    ///     - `pool` The clmm pool object
    ///     - `a2b` The swap direction.
    ///     - `by_amount_in` A flag used to determine whether next arg `amount` represents input or output.
    ///     - `amount` You want to fix the value of the input or output of a swap pre-calculation.
    public fun calculate_swap_result(
        _pool: Object<Pool>,
        _a2b: bool,
        _by_amount_in: bool,
        _amount: u64,
    ): CalculatedSwapResult  {
        abort 0
    }

    /// Get the liquidity by amount
    public fun get_liquidity_from_amount(
        _lower_index: I32,
        _upper_index: I32,
        _current_tick_index: I32,
        _current_sqrt_price: u128,
        _amount: u64,
        _is_fixed_a: bool
    ): (u128, u64, u64) {
        abort 0
    }

    /// Get the coin amount by liquidity
    public fun get_amount_by_liquidity(
        _tick_lower: I32,
        _tick_upper: I32,
        _current_tick_index: I32,
        _current_sqrt_price: u128,
        _liquidity: u128,
        _round_up: bool
    ): (u64, u64) {
        abort 0
    }

    #[view]
    public fun fetch_ticks(_pool: Object<Pool>, _start: vector<u32>, _limit: u64): vector<Tick>  {
        abort 0
    }

    public fun borrow_tick(_pool: Object<Pool>, _tick_idx: I32): Tick  {
        abort 0
    }

    // =============== Getter Methods =================

    #[view]
    public fun pool_metadata_from_address(_pair_addr: address): (Object<Metadata>, Object<Metadata>)  {
        abort 0
    }

    #[view]
    public fun pool_metadata(_pair: Object<Pool>): (Object<Metadata>, Object<Metadata>)  {
        abort 0
    }

    #[view]
    public fun tick_spacing(_pool: Object<Pool>): u32  {
        abort 0
    }

    #[view]
    public fun fee_rate(_pool: Object<Pool>): u64  {
        abort 0
    }

    #[view]
    public fun liquidity(_pool: Object<Pool>): u128  {
        abort 0
    }

    #[view]
    public fun current_sqrt_price(_pool: Object<Pool>): u128 {
        abort 0
    }

    #[view]
    public fun current_tick_index(_pool: Object<Pool>): I32 {
        abort 0
    }

    #[view]
    public fun collection(_pool: Object<Pool>): Object<PositionNftCollection>  {
        abort 0
    }

    #[view]
    public fun protocol_fee(_pool: Object<Pool>): (u64, u64)  {
        abort 0
    }

    #[view]
    public fun balances(_pool: Object<Pool>): (u64, u64)  {
        abort 0
    }

    public fun fees_growth_global(_pool: Object<Pool>): (u128, u128)  {
        abort 0
    }

    public fun is_pause(_pool: Object<Pool>): bool  {
        abort 0
    }

    /// Get the swap pay amount
    public fun swap_pay_amount(_receipt: &FlashSwapReceipt): u64 {
        abort 0
    }

    /// Get the ref fee amount
    public fun ref_fee_amount(_receipt: &FlashSwapReceipt): u64 {
        abort 0
    }

    public fun calculated_swap_result_amount_out(_calculatedSwapResult: &CalculatedSwapResult): u64 {
        abort 0
    }

    public fun calculated_swap_result_is_exceed(_calculatedSwapResult: &CalculatedSwapResult): bool {
        abort 0
    }

    public fun calculated_swap_result_amount_in(_calculatedSwapResult: &CalculatedSwapResult): u64 {
        abort 0
    }

    public fun calculated_swap_result_after_sqrt_price(_calculatedSwapResult: &CalculatedSwapResult): u128 {
        abort 0
    }

    public fun calculated_swap_result_current_sqrt_price(_calculatedSwapResult: &CalculatedSwapResult): u128 {
        abort 0
    }

    public fun calculated_swap_result_fee_amount(_calculatedSwapResult: &CalculatedSwapResult): u64 {
        abort 0
    }

    public fun calculated_swap_result_fee_rate(_calculatedSwapResult: &CalculatedSwapResult): u64 {
        abort 0
    }

    public fun calculated_swap_result_ref_fee_amount(_calculatedSwapResult: &CalculatedSwapResult): u64 {
        abort 0
    }

    public fun calculate_swap_result_step_results(
        _calculatedSwapResult: &CalculatedSwapResult
    ): &vector<SwapStepResult> {
        abort 0
    }

    public fun calculated_swap_result_steps_length(_calculatedSwapResult: &CalculatedSwapResult): u64 {
        abort 0
    }

    public fun calculated_swap_result_step_swap_result(
        _calculatedSwapResult: &CalculatedSwapResult,
        _index: u64
    ): &SwapStepResult {
        abort 0
    }

    public fun step_swap_result_amount_in(_stepSwapResult: &SwapStepResult): u64 {
        return _stepSwapResult.amount_in
    }

    public fun step_swap_result_amount_out(_stepSwapResult: &SwapStepResult): u64 {
        return _stepSwapResult.amount_out
    }

    public fun step_swap_result_fee_amount(_stepSwapResult: &SwapStepResult): u64 {
        return _stepSwapResult.fee_amount
    }

    public fun step_swap_result_current_sqrt_price(_stepSwapResult: &SwapStepResult): u128 {
        return _stepSwapResult.current_sqrt_price
    }

    public fun step_swap_result_target_sqrt_price(_stepSwapResult: &SwapStepResult): u128 {
        return _stepSwapResult.target_sqrt_price
    }

    public fun step_swap_result_current_liquidity(_stepSwapResult: &SwapStepResult): u128 {
        return _stepSwapResult.current_liquidity
    }

    public fun step_swap_result_remainder_amount(_stepSwapResult: &SwapStepResult): u64 {
        return _stepSwapResult.remainder_amount
    }
}
