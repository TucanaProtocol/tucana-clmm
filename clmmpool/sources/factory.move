// Copyright (c) Tucana Technology Limited

/// The factory module is provided to create and manage pools.
/// The `Pools` is a singleton, and the `Pools` is initialized when the contract is deployed.

module tucana_clmm::factory {

    use std::signer;
    use std::string::{String, length};
    use std::option;

    use initia_std::event;
    use initia_std::fungible_asset::Metadata;
    use initia_std::object;
    use initia_std::object::{Object, object_address};
    use initia_std::table::{Self, Table};
    use tucana_clmm::position;

    use tucana_clmm::pool::{Pool, pool_seed};
    use tucana_clmm::tick_math;
    use tucana_clmm::pool;
    use tucana_clmm::config;


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
        account: &signer
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
        creator: &signer,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32,
        initialize_price: u128,
        uri: String
    ): Object<Pool> acquires Pools {
        abort 0
    }

    #[view]
    public fun get_pool(
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32
    ): option::Option<PoolInfo> acquires Pools {
        abort 0
    }

    #[view]
    public fun get_by_id(pool: address): PoolInfo acquires Pools {
        abort 0
    }
}
