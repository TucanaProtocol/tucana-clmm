module tucana_clmm::router {

    use std::option;
    use std::option::Option;
    use std::string::String;
    use std::signer;
    use std::vector;

    use initia_std::coin;
    use initia_std::fungible_asset;
    use initia_std::fungible_asset::Metadata;
    use initia_std::object;
    use initia_std::object::Object;
    use initia_std::primary_fungible_store;

    use tucana_clmm::partner::Partner;
    use tucana_clmm::position;
    use tucana_clmm::position::{PositionNft, is_position_empty};
    use tucana_clmm::pool::{Self, Pool, AddLiquidityReceipt};
    use tucana_clmm::factory;

    const EAmountInAboveMaxLimit: u64 = 1;
    const EAmountOutBelowMinLimit: u64 = 2;
    const ESwapAmountIncorrect: u64 = 3;
    const ELiquidityNotEnoughInAccount: u64 = 4;

    public entry fun create_pool(
        account: &signer,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32,
        initialize_price: u128,
        uri: String
    ) {
        abort 0
    }

    public entry fun open_position(
        account: &signer,
        pool: Object<Pool>,
        tick_lower: u32,
        tick_upper: u32,
    ) {
        abort 0
    }

    public entry fun add_liquidity(
        account: &signer,
        position_nft: Object<PositionNft>,
        delta_liquidity: u128,
        amount_a: u64,
        amount_b: u64
    ) {
        abort 0
    }

    public entry fun add_liquidity_fix_coin(
        account: &signer,
        position_nft: Object<PositionNft>,
        amount_a: u64,
        amount_b: u64,
        fix_amount_a: bool,
    ) {
        abort 0
    }

    public entry fun remove_liquidity(
        account: &signer,
        position_nft: Object<PositionNft>,
        delta_liquidity: u128,
        min_amount_a: u64,
        min_amount_b: u64,
    ) {
        abort 0
    }

    public entry fun close_position(
        account: &signer,
        position_nft: Object<PositionNft>,
    ) {
        abort 0
    }


    public entry fun collect_fee(
        account: &signer,
        position_nft: Object<PositionNft>,
    ) {
        abort 0
    }

    public entry fun collect_rewards(
        account: &signer,
        position_nft: Object<PositionNft>,
    ) {
        abort 0
    }

    public entry fun create_pool_with_liquidity_with_all(
        account: &signer,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32,
        initialize_price: u128,
        uri: String,
        tick_lower: u32,
        tick_upper: u32,
        amount_a: u64,
        amount_b: u64,
        fix_amount_a: bool,
    ) {
        abort 0
    }

    public entry fun open_position_with_liquidity_with_all(
        account: &signer,
        pool: Object<Pool>,
        tick_lower: u32,
        tick_upper: u32,
        amount_a: u64,
        amount_b: u64,
        fix_amount_a: bool,
    ) {
        abort 0
    }

    public entry fun remove_liquidity_with_option(
        account: &signer,
        position_nft: Object<PositionNft>,
        delta_liquidity: u128,
        min_amount_a: u64,
        min_amount_b: u64,
        is_collect_fee: Option<bool>,
        is_collect_reward: Option<bool>,
    ) {
        abort 0
    }

    public entry fun swap(
        account: &signer,
        pool: Object<Pool>,
        a_to_b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_limit: u128,
    ) {
        abort 0
    }

    public entry fun swap_with_partner(
        account: &signer,
        pool: Object<Pool>,
        partner: Object<Partner>,
        a_to_b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_limit: u128,
    ) {
        abort 0
    }
}
