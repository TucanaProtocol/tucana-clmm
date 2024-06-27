// Copyright (c) Tucana Technology Limited
/// `Rewarder` is the liquidity incentive module of `clmmpool`, which is commonly known as `farming`. In `clmmpool`,
/// liquidity is stored in a price range, so `clmmpool` uses a reward allocation method based on effective liquidity.
/// The allocation rules are roughly as follows:
///
/// 1. Each pool can configure multiple `Rewarders`, and each `Rewarder` releases rewards at a uniform speed according
/// to its configured release rate.
/// 2. During the time period when the liquidity price range contains the current price of the pool, the liquidity
/// position can participate in the reward distribution for this time period (if the pool itself is configured with
/// rewards), and the proportion of the distribution depends on the size of the liquidity value of the position.
/// Conversely, if the price range of a position does not include the current price of the pool during a certain period
/// of time, then this position will not receive any rewards during this period of time. This is similar to the
/// calculation of transaction fees.
module tucana_clmm::rewarder {
    use std::option::{Option};

    use initia_std::fungible_asset::{Metadata, FungibleAsset};
    use initia_std::object::{Object, ExtendRef};

    friend tucana_clmm::pool;

    const REWARDER_NUM: u64 = 3;
    const DAYS_IN_SECONDS: u128 = 24 * 60 * 60;

    // =============== Errors =================

    const ERewardSoltIsFull: u64 = 1;
    const ERewardAlreadyExist: u64 = 2;
    const EInvalidTime: u64 = 3;
    const ERewardAmountInsufficient: u64 = 4;
    const ERewardNotExist: u64 = 5;
    const EIncorrectWithdrawAmount: u64 = 6;

    // =============== Structs =================


    /// Manager the Rewards.
    struct RewarderManager has store {
        _rewarders: vector<Rewarder>,
        _last_updated_time: u64,
    }

    /// Rewarder store the information of a rewarder.
    /// `reward_metadata` is the type of reward coin.
    /// `emissions_per_second` is the amount of reward coin emit per second.
    /// `growth_global` is Q64.X64,  is reward emited per liquidity.
    struct Rewarder has copy, drop, store {
        _reward_metadata: Object<Metadata>,
        _emissions_per_second: u128,
        _growth_global: u128,
        _released: u256,
        _harvested: u64,
        _end_time: u64
    }

    /// RewarderGlobalVault Store the Rewarders Fungible Assets.
    struct RewarderGlobalVault has key, store {
        _extend_ref: ExtendRef
    }

    // ============= Events =================

    #[event]
    /// Emit when withdraw reward.
    struct EmergentWithdrawEvent has drop, store {
        _metadata_addr: address,
        _withdraw_amount: u64,
        _after_amount: u64
    }

    /// Add rewarder into `RewarderManager`
    /// Only support at most REWARDER_NUM rewarders.
    public fun add_rewarder(_manager: &mut RewarderManager, _metadata: Object<Metadata>) {
        abort 0
    }

    /// Accumulate the reward.
    /// Update the last_updated_time, the growth_global of each rewarder.
    /// Settlement is needed when swap, modify position liquidity, update emission speed.
    public fun accumulate_reward(
        _manager: &mut RewarderManager,
        _liquidity: u128,
    ) {
        abort 0
    }

    /// Update the reward emission speed.
    /// The reward balance at least enough for one day should in `RewarderGlobalVault` when the emission speed is not zero.
    /// The reward settlement is needed when update the emission speed.
    /// emissions_per_second is Q64.X64
    /// Params
    ///     - `manager`: `RewarderManager`
    ///     - `metadata`: The reward coin metadata
    ///     - `liquidity`: The pool current liquidity
    ///     - `emission_per_second` The emission reward per second
    ///     - end_tiome
    public fun update_emission(
        _manager: &mut RewarderManager,
        _metadata: Object<Metadata>,
        _liquidity: u128,
        _emissions_per_second: u128,
        _end_time: u64
    ) {
        abort 0
    }

    /// Withdraw Reward from `RewarderGlobalVault`
    /// This method is used for claim reward in pool and emergent_withdraw.
    public(friend) fun withdraw_reward(
        _manager: &mut RewarderManager,
        _metadata: Object<Metadata>,
        _amount: u64
    ): FungibleAsset {
        abort 0
    }

    /// Withdraw reward Asset from vault by the protocol admin.
    /// This function is only used for emergency.
    /// Params
    ///     - `manager`: The admin manager signer
    ///     - `metadata`: The reward coin metadata
    ///     - `amount`: the amount of reward Balance to withdraw.
    public entry fun emergent_withdraw(
        _manager: &signer,
        _metadata: Object<Metadata>,
        _amount: u64
    ) {
        abort 0
    }


    #[view]
    /// Get the rewarder global vault address
    public fun vault_address(): address {
        abort 0
    }

    /// get the rewarders
    public fun rewarders(_manager: &RewarderManager): vector<Rewarder> {
        abort 0
    }

    /// get the reward_growth_globals
    public fun rewards_growth_global(_manager: &RewarderManager): vector<u128> {
        abort 0
    }

    /// get the last_updated_time
    public fun last_update_time(_manager: &RewarderManager): u64 {
        abort 0
    }

    /// get the rewarder coin Type.
    public fun reward_metadata(_rewarder: &Rewarder): Object<Metadata> {
        abort 0
    }

    /// get the rewarder emissions_per_second.
    public fun emissions_per_second(_rewarder: &Rewarder): u128 {
        abort 0
    }

    /// get the rewarder growth_global.
    public fun growth_global(_rewarder: &Rewarder): u128 {
        abort 0
    }

    /// Get index of CoinType in `RewarderManager`, if not exists, return `None`
    public fun rewarder_index(_manager: &RewarderManager, _metadata: Object<Metadata>): Option<u64> {
        abort 0
    }

    /// Borrow `Rewarder` from `RewarderManager`
    public fun borrow_rewarder(_manager: &RewarderManager, _metadata: Object<Metadata>): &Rewarder {
        abort 0
    }

    /// Borrow mutable `Rewarder` from `RewarderManager
    fun borrow_mut_rewarder(_manager: &mut RewarderManager, _metadata: Object<Metadata>): &mut Rewarder {
        abort 0
    }
}
