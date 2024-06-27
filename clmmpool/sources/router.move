module tucana_clmm::router {
    use std::option::Option;
    use std::string::String;

    use initia_std::fungible_asset::Metadata;
    use initia_std::object::Object;

    use tucana_clmm::partner::Partner;
    use tucana_clmm::position::{PositionNft};
    use tucana_clmm::pool::{Pool};

    const EAmountInAboveMaxLimit: u64 = 1;
    const EAmountOutBelowMinLimit: u64 = 2;
    const ESwapAmountIncorrect: u64 = 3;
    const ELiquidityNotEnoughInAccount: u64 = 4;

    public entry fun create_pool(
        _account: &signer,
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32,
        _initialize_price: u128,
        _uri: String
    ) {
        abort 0
    }

    public entry fun open_position(
        _account: &signer,
        _pool: Object<Pool>,
        _tick_lower: u32,
        _tick_upper: u32,
    ) {
        abort 0
    }

    public entry fun add_liquidity(
        _account: &signer,
        _position_nft: Object<PositionNft>,
        _delta_liquidity: u128,
        _amount_a: u64,
        _amount_b: u64
    ) {
        abort 0
    }

    public entry fun add_liquidity_fix_coin(
        _account: &signer,
        _position_nft: Object<PositionNft>,
        _amount_a: u64,
        _amount_b: u64,
        _fix_amount_a: bool,
    ) {
        abort 0
    }

    public entry fun remove_liquidity(
        _account: &signer,
        _position_nft: Object<PositionNft>,
        _delta_liquidity: u128,
        _min_amount_a: u64,
        _min_amount_b: u64,
    ) {
        abort 0
    }

    public entry fun close_position(
        _account: &signer,
        _position_nft: Object<PositionNft>,
    ) {
        abort 0
    }


    public entry fun collect_fee(
        _account: &signer,
        _position_nft: Object<PositionNft>,
    ) {
        abort 0
    }

    public entry fun collect_rewards(
        _account: &signer,
        _position_nft: Object<PositionNft>,
    ) {
        abort 0
    }

    public entry fun create_pool_with_liquidity_with_all(
        _account: &signer,
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32,
        _initialize_price: u128,
        _uri: String,
        _tick_lower: u32,
        _tick_upper: u32,
        _amount_a: u64,
        _amount_b: u64,
        _fix_amount_a: bool,
    ) {
        abort 0
    }

    public entry fun open_position_with_liquidity_with_all(
        _account: &signer,
        _pool: Object<Pool>,
        _tick_lower: u32,
        _tick_upper: u32,
        _amount_a: u64,
        _amount_b: u64,
        _fix_amount_a: bool,
    ) {
        abort 0
    }

    public entry fun remove_liquidity_with_option(
        _account: &signer,
        _position_nft: Object<PositionNft>,
        _delta_liquidity: u128,
        _min_amount_a: u64,
        _min_amount_b: u64,
        _is_collect_fee: Option<bool>,
        _is_collect_reward: Option<bool>,
    ) {
        abort 0
    }

    public entry fun swap(
        _account: &signer,
        _pool: Object<Pool>,
        _a_to_b: bool,
        _by_amount_in: bool,
        _amount: u64,
        _amount_limit: u64,
        _sqrt_price_limit: u128,
    ) {
        abort 0
    }

    public entry fun swap_with_partner(
        _account: &signer,
        _pool: Object<Pool>,
        _partner: Object<Partner>,
        _a_to_b: bool,
        _by_amount_in: bool,
        _amount: u64,
        _amount_limit: u64,
        _sqrt_price_limit: u128,
    ) {
        abort 0
    }
}
