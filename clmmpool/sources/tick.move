// Copyright (c) Tucana Technology Limited

/// The `tick` module is a module that is designed to facilitate the management of `tick` owned by `Pool`.
/// All `tick` related operations of `Pool` are handled by this module.
module tucana_clmm::tick {
    use std::option::{Self, Option};
    use std::vector;
    use initia_std::block;

    use tucana_std::i32::{Self, I32};
    use tucana_std::i128::{Self, I128};
    use tucana_std::math_u128;
    use tucana_std::skip_list_u64::{Self, SkipListU64};
    use tucana_std::option_u64::{Self, OptionU64};

    use tucana_clmm::tick_math;

    friend tucana_clmm::pool;

    // =============== Errors =================

    const ELiquidityOverflow: u64 = 0;
    const ELiquidityUnderflow: u64 = 1;
    const EInvalidTick: u64 = 2;
    const ETickNotFound: u64 = 3;

    // =============== Structs =================

    /// Manager ticks of a pool, ticks is organized into SkipList.
    struct TickManager has store {
        tick_spacing: u32,
        ticks: SkipListU64<Tick>
    }

    /// Tick infos.
    struct Tick has copy, drop, store {
        index: I32,
        sqrt_price: u128,
        liquidity_net: I128,
        liquidity_gross: u128,
        fee_growth_outside_a: u128,
        fee_growth_outside_b: u128,
        rewards_growth_outside: vector<u128>,
    }

    /// Increase liquidity on Ticks.
    /// If the tick not exists, insert into skip_list_u64 first.
    public fun increase_liquidity(
        manager: &mut TickManager,
        pool_current_tick_idx: I32,
        tick_lower_idx: I32,
        tick_upper_idx: I32,
        delta_liquidity: u128,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        rewards_growth_global: vector<u128>
    ) {
        abort 0
    }

    /// Decrease liquidity on Ticks.
    /// if the tick liquidity is zero, remove from skip_list_u64(skip for max_tick and min_tick);
    public fun decrease_liquidity(
        manager: &mut TickManager,
        pool_current_tick_index: I32,
        tick_lower_idx: I32,
        tick_upper_idx: I32,
        delta_liquidity: u128,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        rewards_growth_global: vector<u128>
    ) {
        abort 0
    }


    /// When the swap cross the tick, the current liquidity of the pool will change.
    /// Also the Tick infos will reverse.
    /// Params
    ///     - manager: the TickManager
    ///     - tick_idx: the tick index
    ///     - a2b: if the swap is a2b or b2a
    ///     - pool_current_liquidity: the current liquidity of the pool
    ///     - fee_growth_global_a
    ///     - fee_growth_global_b
    ///     - reward_growth_globals
    public fun cross_by_swap(
        manager: &mut TickManager,
        tick_idx: I32,
        a2b: bool,
        pool_current_liquidity: u128,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        reward_growth_globals: vector<u128>
    ): u128 {
        abort 0
    }

    /// return the next tick index for swap.
    public fun first_score_for_swap(
        manager: &TickManager,
        current_tick_idx: I32,
        a2b: bool,
    ): OptionU64 {
        abort 0
    }

    /// Borrow Tick by score and return the next tick score for swap.
    public fun borrow_tick_for_swap(manager: &TickManager, score: u64, a2b: bool): (&Tick, OptionU64) {
        abort 0
    }

    /// Get tick_spacing.
    public fun tick_spacing(manager: &TickManager): u32 {
        manager.tick_spacing
    }

    /// Get tick index
    public fun index(tick: &Tick): I32 {
        tick.index
    }

    /// Get tick sqrt_price
    public fun sqrt_price(tick: &Tick): u128 {
        tick.sqrt_price
    }

    /// Get tick liquidity_net
    public fun liquidity_net(tick: &Tick): I128 {
        tick.liquidity_net
    }

    /// Get tick liquidity_gross
    public fun liquidity_gross(tick: &Tick): u128 {
        tick.liquidity_gross
    }

    /// Get tick fee_growth_insides
    public fun fee_growth_outside(tick: &Tick): (u128, u128) {
        (tick.fee_growth_outside_a, tick.fee_growth_outside_b)
    }

    /// Get tick rewards_growth_outside
    public fun rewards_growth_outside(tick: &Tick): &vector<u128> {
        abort 0
    }

    /// Borrow Tick by index
    public fun borrow_tick(manager: &TickManager, idx: I32): &Tick {
        abort 0
    }

    /// Get the tick reward_growth_outside by index.
    public fun get_reward_growth_outside(tick: &Tick, idx: u64): u128 {
        abort 0
    }

    /// Get the fee inside in tick range.
    public fun get_fee_in_range(
        pool_current_tick_index: I32,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        op_tick_lower: Option<Tick>,
        op_tick_upper: Option<Tick>
    ): (u128, u128) {
        abort 0
    }

    /// Get the rewards inside in tick range.
    public fun get_rewards_in_range(
        pool_current_tick_index: I32,
        rewards_growth_globals: vector<u128>,
        op_tick_lower: Option<Tick>,
        op_tick_upper: Option<Tick>
    ): vector<u128> {
        abort 0
    }

    /// Fetch Ticks
    /// Params
    ///     -start: start tick index
    ///     - limit: max number of ticks to fetch
    public fun fetch_ticks(
        manager: &TickManager,
        start: vector<u32>,
        limit: u64
    ): vector<Tick> {
        abort 0
    }
}