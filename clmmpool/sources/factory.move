
// Copyright (c) Tucana Technology Limited

/// The factory module is provided to create and manage pools.
/// The `Pools` is a singleton, and the `Pools` is initialized when the contract is deployed.
module tucana_clmm::factory {
    use std::string::String;
    use std::option;

    use initia_std::fungible_asset::Metadata;
    use initia_std::object::Object;
    use initia_std::table::Table;

    use tucana_clmm::pool::Pool;


    // =============== Errors =================

    const EPOOL_ALREADY_INITIALIZED: u64 = 1;
    const EINVALID_SQRTPRICE: u64 = 2;

    // =============== Structs =================

    struct PoolInfo has copy, store, drop {
        pool_id: address,
        coin_type_a: address,
        coin_type_b: address,
        tick_spacing: u32
    }

    /// Store the pools created in the protoco into @tucana_clmm account.
    struct Pools has key {
        // key -> PoolInfo
        pools: Table<address, PoolInfo>,
        // pool_id -> PoolInfo
        id_to_info: Table<address, PoolInfo>,
        index: u64,
    }

    #[event]
    /// Emit when create a pool
    struct CreatePoolEvent has drop, store {
        creator: address,
        pool_address: address,
        coin_type_a: address,
        coin_type_b: address,
        tick_spacing: u32
    }

    /// Store the Pools resource into deployed account.
    fun init_module(
        _account: &signer
    ) {
        abort 0
    }

    /// Create pool
    /// Params
    ///     - metadata_a: coin_a metadata address
    ///     - metadata_b: coin_b metadata address
    ///     - tick_spacing
    ///     - initialize_price
    ///     - uri: position uri in this pool
    public fun create_pool(
        _creator: &signer,
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32,
        _initialize_price: u128,
        _uri: String
    ): Object<Pool> {
        abort 0
    }

    #[view]
    public fun get_pool(
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32
    ): option::Option<PoolInfo> {
        abort 0
    }

    #[view]
    public fun get_by_id(_pool: address): PoolInfo {
        abort 0
    }
}
