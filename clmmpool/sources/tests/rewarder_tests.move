#[test_only]
module tucana_clmm::rewarder_tests {

    use std::option;
    use std::signer;
    use std::vector;
    use initia_std::block::set_block_info;
    use initia_std::debug;
    use initia_std::fungible_asset;
    use initia_std::fungible_asset::{FungibleAsset, MintRef, Metadata};
    use initia_std::object;
    use initia_std::object::Object;
    use initia_std::primary_fungible_store;
    use tucana_clmm::rewarder::vault_address;
    use tucana_clmm::tick;
    use tucana_clmm::position;
    use tucana_clmm::pool_tests::{open_position_with_liquidity, remove_liquidity, add_liquidity, pt, nt, swap};
    use tucana_std::i32;
    use tucana_clmm::tick_math::{get_sqrt_price_at_tick, min_sqrt_price, max_sqrt_price};
    use tucana_clmm::pool::pool_metadata;
    use tucana_clmm::rewarder;
    use tucana_clmm::config;
    use tucana_clmm::position::PositionNft;
    use tucana_clmm::pool;

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_initialize_rewarder(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, mint_ref1, _mint_ref2) = pool::new_for_test(
            user,
            mod,
            2,
            19218706184437883591,
            2000
        );
        let (metadata_a, _) = pool_metadata(pool);
        pool::initialize_rewarder(user, pool, metadata_a, 0, 100000000);
        let rewarder = pool::borrow_rewarder(pool, metadata_a);
        assert!(rewarder::emissions_per_second(&rewarder) == 0, 0);
        assert!(rewarder::growth_global(&rewarder) == 0, 0);

        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        pool::update_emission(user, pool, metadata_a, 1 << 64, 100000000);
        let rewarder = pool::borrow_rewarder(pool, metadata_a);
        assert!(rewarder::emissions_per_second(&rewarder) == (1 << 64), 0);
        let rewarder_index = pool::rewarder_index(pool, metadata_a);
        assert!(option::extract(&mut rewarder_index) == 0, 0);
    }


    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_collect_rewards(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (metadata_a, _) = pool_metadata(pool);
        pool::initialize_rewarder(user, pool, metadata_a, 0, 100000000);
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        pool::update_emission(user, pool, metadata_a, 1 << 64, 100000000);

        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            1000000,
        );
        set_block_info(12, 6000);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 5999, 0);
        primary_fungible_store::deposit(signer::address_of(user), rewarder_balance);

        let position_2 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            1000000,
        );
        set_block_info(12, 6000 * 2);
        let reward_balance_1 = pool::collect_rewards(
            user,
            position_1,
        );
        let reward_balance_2 = pool::collect_rewards(
            user,
            position_2,
        );
        primary_fungible_store::deposit(signer::address_of(user), vector::pop_back(&mut reward_balance_1));
        primary_fungible_store::deposit(signer::address_of(user), vector::pop_back(&mut reward_balance_2));
        vector::destroy_empty(reward_balance_1);
        vector::destroy_empty(reward_balance_2);
        set_block_info(12, 6000 * 3);
        pool::update_emission(user, pool, metadata_a, 2 << 64, 100000000000);
        set_block_info(12, 6000 * 4);
        let need_rewards_1 = pool::calculate_and_update_rewards(
            position_1
        );
        assert!(need_rewards_1 == position::rewards_amount_owned(position_1), 0);
        let reward_balance_1 = pool::collect_rewards(user, position_1);

        let need_rewards_2 = pool::calculate_and_update_rewards(position_2);
        assert!(need_rewards_2 == position::rewards_amount_owned(position_2), 0);
        let reward_balance_2 = pool::collect_rewards(user, position_2);
        let r1 = vector::pop_back(&mut reward_balance_1);
        let r2 = vector::pop_back(&mut reward_balance_2);
        vector::destroy_empty(reward_balance_1);
        vector::destroy_empty(reward_balance_2);
        let amount1 = fungible_asset::amount(&r1);
        let amount2 = fungible_asset::amount(&r2);
        assert!(amount1 == vector::pop_back(&mut need_rewards_1), 0);
        assert!(amount2 == vector::pop_back(&mut need_rewards_2), 0);
        assert!(amount1 == 8999, 0);
        assert!(amount2 == 8999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);

        let position_metadata1 = position::position_metadata(position_1);
        let liquidity = position::position_liquidity(&position_metadata1);
        remove_liquidity(
            user,
            pool,
            position_1,
            liquidity,
        );
        set_block_info(12, 6000 * 5);
        let need_reward_1 = pool::calculate_and_update_rewards(
            position_1,
        );
        assert!(need_reward_1 == position::rewards_amount_owned(position_1), 0);
        let reward_balance_1 = pool::collect_rewards(
            user,
            position_1,
        );
        assert!(need_reward_1 == vector[0], 0);
        fungible_asset::destroy_zero(vector::pop_back(&mut reward_balance_1));
        vector::destroy_empty(reward_balance_1);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_collect_reward_and_position_open_with_full_range(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (metadata_a, _) = pool_metadata(pool);
        pool::initialize_rewarder(user, pool, metadata_a, 0, 100000000);
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        pool::update_emission(user, pool, metadata_a, 1 << 64, 100000000);

        let (min_tick, max_tick) = (4294523661, 443635);

        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            1000000,
        );
        set_block_info(11, 6000);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let reward_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&reward_balance) == 5999, 0);
        primary_fungible_store::deposit(signer::address_of(user), reward_balance);

        let position_2 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            min_tick,
            max_tick,
            1000000,
        );
        set_block_info(11, 6000 * 2);
        let reward_balances_1 = pool::collect_rewards(
            user,
            position_1,
        );
        let reward_balances_2 = pool::collect_rewards(user, position_2);
        primary_fungible_store::deposit(signer::address_of(user), vector::pop_back(&mut reward_balances_1));
        primary_fungible_store::deposit(signer::address_of(user), vector::pop_back(&mut reward_balances_2));
        vector::destroy_empty(reward_balances_1);
        vector::destroy_empty(reward_balances_2);
        set_block_info(11, 6000 * 3);
        pool::update_emission(user, pool, metadata_a, 2 << 64, 100000000000);
        set_block_info(11, 6000 * 4);
        let need_rewards_1 = pool::calculate_and_update_rewards(position_1);
        assert!(need_rewards_1 == position::rewards_amount_owned(position_1), 0);

        let reward_balance_1 = pool::collect_rewards(user, position_1);
        let need_rewards_2 = pool::calculate_and_update_rewards(position_2);

        assert!(need_rewards_1 == position::rewards_amount_owned(position_2), 0);
        let reward_balance_2 = pool::collect_rewards(user, position_2);

        let r1 = vector::pop_back(&mut reward_balance_1);
        let r2 = vector::pop_back(&mut reward_balance_2);
        vector::destroy_empty(reward_balance_1);
        vector::destroy_empty(reward_balance_2);
        let amount1 = fungible_asset::amount(&r1);
        let amount2 = fungible_asset::amount(&r2);
        assert!(amount1 == vector::pop_back(&mut need_rewards_1), 0);
        assert!(amount2 == vector::pop_back(&mut need_rewards_2), 0);
        assert!(amount1 == 8999, 0);
        assert!(amount2 == 8999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);


        let position_metadata1 = position::position_metadata(position_1);
        let liquidity = position::position_liquidity(&position_metadata1);
        remove_liquidity(
            user,
            pool,
            position_1,
            liquidity,
        );
        set_block_info(12, 6000 * 5);
        let need_reward_1 = pool::calculate_and_update_rewards(
            position_1,
        );
        assert!(need_reward_1 == position::rewards_amount_owned(position_1), 0);
        let reward_balance_1 = pool::collect_rewards(
            user,
            position_1,
        );
        assert!(need_reward_1 == vector[0], 0);
        fungible_asset::destroy_zero(vector::pop_back(&mut reward_balance_1));
        vector::destroy_empty(reward_balance_1);

        let position_metadata2 = position::position_metadata(position_2);
        let liquidity = position::position_liquidity(&position_metadata2);

        remove_liquidity(
            user,
            pool,
            position_2,
            liquidity,
        );
        let reward_balance_1 = pool::collect_rewards(
            user,
            position_2,
        );
        let r1 = vector::pop_back(&mut reward_balance_1);
        vector::destroy_empty(reward_balance_1);
        assert!(fungible_asset::amount(&r1) == 11999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);

        add_liquidity(
            pool,
            &mint_ref1,
            &mint_ref2,
            position_2,
            liquidity,
        );
        set_block_info(12, 6000 * 6);
        let reward_balance_1 = pool::collect_rewards(user, position_1);
        let reward_balance_2 = pool::collect_rewards(user, position_2);
        let r1 = vector::pop_back(&mut reward_balance_1);
        let r2 = vector::pop_back(&mut reward_balance_2);
        vector::destroy_empty(reward_balance_1);
        vector::destroy_empty(reward_balance_2);
        assert!(fungible_asset::amount(&r1) == 0, 1);
        assert!(fungible_asset::amount(&r2) == 11999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);
    }

    #[test_only]
    fun prepare_tokens(
        admin: &signer,
    ): (MintRef, Object<Metadata>, MintRef, Object<Metadata>, MintRef, Object<Metadata>) {
        // primary_fungible_store::init_module_for_test(mod);
        let creator_ref1 = object::create_named_object(admin, b"TEST", false);
        let (mint_ref1, _, _) = pool::init_test_metadata_with_primary_store_enabled(&creator_ref1);

        let creator_ref2 = object::create_named_object(admin, b"TEFFST", false);
        let (mint_ref2, _, _) = pool::init_test_metadata_with_primary_store_enabled(&creator_ref2);

        let creator_ref3 = object::create_named_object(admin, b"TEFFSTFF", false);
        let (mint_ref3, _, _) = pool::init_test_metadata_with_primary_store_enabled(&creator_ref3);

        let metadata1 = object::object_from_constructor_ref<Metadata>(&creator_ref1);
        let metadata2 = object::object_from_constructor_ref<Metadata>(&creator_ref2);
        let metadata3 = object::object_from_constructor_ref<Metadata>(&creator_ref3);

        (mint_ref1, metadata1, mint_ref2, metadata2, mint_ref3, metadata3)
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_collect_reward_position_open_before_init(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, pmint_ref1, pmint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (mint_ref1, m1, mint_ref2, m2, mint_ref3, _m3) = prepare_tokens(user);

        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref2, 100000000));
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref3, 100000000));

        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294966296,
            1000,
            1000000,
        );
        let position_2 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294965296,
            2000,
            1000000,
        );
        set_block_info(12, 60000);

        pool::initialize_rewarder(user, pool, m1, 0, 1000000000);
        pool::update_emission(user, pool, m1, 2 << 64, 1000000000);
        set_block_info(12, 60000 * 2);

        let tick_upper_1 = pool::borrow_tick(pool, pt(1000));
        let tick_lower_1 = pool::borrow_tick(pool, nt(1000));
        let tick_upper_2 = pool::borrow_tick(pool, pt(2000));
        let tick_lower_2 = pool::borrow_tick(pool, nt(2000));
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_1)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_1)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_2)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_2)) == 0, 0);
        assert!(vector::length(&position::position_rewards(position_1)) == 0, 0);

        let reward_balance_1 = pool::collect_rewards(user, position_1);

        let tick_upper_1 = pool::borrow_tick(pool, pt(1000));
        let tick_lower_1 = pool::borrow_tick(pool, nt(1000));
        let tick_upper_2 = pool::borrow_tick(pool, pt(2000));
        let tick_lower_2 = pool::borrow_tick(pool, nt(2000));
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_1)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_1)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_2)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_2)) == 0, 0);
        assert!(vector::length(&position::position_rewards(position_1)) == 1, 0);
        let r1 = vector::pop_back(&mut reward_balance_1);
        debug::print(&fungible_asset::amount(&r1));
        assert!(fungible_asset::amount(&r1) == 59999, 0);


        // will cross -1000
        swap(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            true,
            true,
            130000,
            min_sqrt_price(),
        );
        let tick_upper_1 = pool::borrow_tick(pool, pt(1000));
        let tick_lower_1 = pool::borrow_tick(pool, nt(1000));
        let tick_upper_2 = pool::borrow_tick(pool, pt(2000));
        let tick_lower_2 = pool::borrow_tick(pool, nt(2000));
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_1)) == 1, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_1)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_2)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_2)) == 0, 0);
        let reward_balance_2 = pool::collect_rewards(user, position_2);

        let tick_upper_1 = pool::borrow_tick(pool, pt(1000));
        let tick_lower_1 = pool::borrow_tick(pool, nt(1000));
        let tick_upper_2 = pool::borrow_tick(pool, pt(2000));
        let tick_lower_2 = pool::borrow_tick(pool, nt(2000));
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_1)) == 1, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_1)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_2)) == 0, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_2)) == 0, 0);
        assert!(vector::length(&position::position_rewards(position_2)) == 1, 0);
        set_block_info(12, 2 * 60000 + 6000);

        let position_3 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294964296,
            3000,
            1000000,
        );
        set_block_info(12, 2 * 60000 + 6000 * 2);
        let reward_balance_3 = pool::collect_rewards(user, position_3);

        let tick_upper_3 = pool::borrow_tick(pool, pt(3000));
        let tick_lower_3 = pool::borrow_tick(pool, nt(3000));
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_3)) == 1, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_3)) == 1, 0);
        assert!(vector::length(&position::position_rewards(position_3)) == 1, 0);
        // position-1 had out range
        // let r1 = vector::pop_back(&mut reward_balance_1);
        let r2 = vector::pop_back(&mut reward_balance_2);
        let r3 = vector::pop_back(&mut reward_balance_3);
        assert!(fungible_asset::amount(&r3) == 5999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);
        primary_fungible_store::deposit(signer::address_of(user), r3);
        vector::destroy_empty(reward_balance_1);
        vector::destroy_empty(reward_balance_2);
        vector::destroy_empty(reward_balance_3);


        pool::initialize_rewarder(user, pool, m2, 0, 10000000000);
        pool::update_emission(user, pool, m2, 2 << 64, 10000000000);
        set_block_info(12, 2 * 60000 + 6000 * 3);

        let tick_upper_3 = pool::borrow_tick(pool, pt(3000));
        let tick_lower_3 = pool::borrow_tick(pool, nt(3000));
        assert!(vector::length(tick::rewards_growth_outside(&tick_lower_3)) == 1, 0);
        assert!(vector::length(tick::rewards_growth_outside(&tick_upper_3)) == 1, 0);
        assert!(vector::length(&position::position_rewards(position_3)) == 1, 0);
        let reward_balance = pool::collect_rewards(user, position_3);
        assert!(vector::length(&reward_balance) == 2, 1);

        add_liquidity(pool, &pmint_ref1, &pmint_ref2, position_3, 1000000);
        let r1 = vector::pop_back(&mut reward_balance);
        let r2 = vector::pop_back(&mut reward_balance);
        vector::destroy_empty(reward_balance);
        assert!(fungible_asset::amount(&r1) == 5999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);

        set_block_info(12, 2 * 60000 + 6000 * 4);
        let reward_balance = pool::collect_rewards(user, position_3);
        let r1 = vector::pop_back(&mut reward_balance);
        let r2 = vector::pop_back(&mut reward_balance);
        assert!(fungible_asset::amount(&r1) == 7999, 0);
        vector::destroy_empty(reward_balance);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);

        let position_metadta2 = position::position_metadata(position_2);
        let liquidity = position::position_liquidity(&position_metadta2);
        remove_liquidity(
            user,
            pool,
            position_2,
            liquidity,
        );
        let reward_balances_2 = pool::collect_rewards(user, position_2);
        let r1 = vector::pop_back(&mut reward_balances_2);
        let r2 = vector::pop_back(&mut reward_balances_2);
        assert!(fungible_asset::amount(&r1) == 9999, 0);
        assert!(fungible_asset::amount(&r2) == 27999, 0);
        primary_fungible_store::deposit(signer::address_of(user), r1);
        primary_fungible_store::deposit(signer::address_of(user), r2);
        vector::destroy_empty(reward_balances_2);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_multi_rewarder_and_swap_cross(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, pmint_ref1, pmint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (mint_ref1, m1, mint_ref2, m2, mint_ref3, m3) = prepare_tokens(user);

        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref2, 100000000));
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref3, 100000000));


        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294966296,
            1000,
            1000000,
        );
        let position_2 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294965296,
            2000,
            1000000,
        );
        let position_3 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294767296,
            200000,
            1000000,
        );
        pool::initialize_rewarder(user, pool, m1, 1 << 64, 1000000000);
        pool::initialize_rewarder(user, pool, m2, 2 << 64, 1000000000);
        pool::initialize_rewarder(user, pool, m3, 3 << 64, 1000000000);

        set_block_info(12, 1000);

        // left cross tick -1000
        swap(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            true,
            true,
            200000,
            min_sqrt_price(),
        );
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_1 == rewards_2, 0);
        assert!(rewards_1 == rewards_3, 0);

        set_block_info(12, 1000 * 2);
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_2 == vector[832, 1665, 2498], 0);
        assert!(rewards_3 == vector[832, 1665, 2498], 0);

        // left cross tick -2000
        swap(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            true,
            true,
            500000,
            min_sqrt_price(),
        );
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_2 == vector[832, 1665, 2498], 0);
        assert!(rewards_3 == vector[832, 1665, 2498], 0);

        set_block_info(12, 1000 * 3);
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_2 == vector[832, 1665, 2498], 0);
        assert!(rewards_3 == vector[1831, 3664, 5497], 0);

        // right cross tick -2000
        swap(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            false,
            true,
            300000,
            max_sqrt_price(),
        );
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_2 == vector[832, 1665, 2498], 0);
        assert!(rewards_3 == vector[1831, 3664, 5497], 0);

        set_block_info(12, 1000 * 4);
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_2 == vector[1331, 2664, 3997], 0);
        assert!(rewards_3 == vector[2330, 4663, 6996], 0);

        // right cross tick -1000
        swap(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            false,
            true,
            200000,
            max_sqrt_price(),
        );
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[333, 666, 999], 0);
        assert!(rewards_2 == vector[1331, 2664, 3997], 0);
        assert!(rewards_3 == vector[2330, 4663, 6996], 0);
        set_block_info(12, 1000 * 5);
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[ 666, 1332, 1998  ], 0);
        assert!(rewards_2 == vector[ 1664, 3330, 4996 ], 0);
        assert!(rewards_3 == vector[ 2663, 5329, 7995 ], 0);

        // right cross tick 1000
        swap(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            false,
            true,
            200000,
            max_sqrt_price(),
        );
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[ 666, 1332, 1998  ], 0);
        assert!(rewards_2 == vector[ 1664, 3330, 4996 ], 0);
        assert!(rewards_3 == vector[ 2663, 5329, 7995 ], 0);
        set_block_info(12, 1000 * 6);
        let rewards_1 = pool::calculate_and_update_rewards(position_1);
        let rewards_2 = pool::calculate_and_update_rewards(position_2);
        let rewards_3 = pool::calculate_and_update_rewards(position_3);
        assert!(rewards_1 == vector[ 666, 1332, 1998  ], 0);
        assert!(rewards_2 == vector[ 2163, 4329, 6495 ], 0);
        assert!(rewards_3 == vector[ 3162, 6328, 9494 ], 0);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_multi_rewarder_release_total(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, pmint_ref1, pmint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (mint_ref1, m1, mint_ref2, m2, mint_ref3, m3) = prepare_tokens(user);

        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref2, 100000000));
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref3, 100000000));

        let receipt_c = fungible_asset::zero(m1);
        let receipt_d = fungible_asset::zero(m2);
        let receipt_e = fungible_asset::zero(m3);
        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294966296,
            1000,
            1000000,
        );
        let position_2 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294965296,
            2000,
            1000000,
        );
        let position_3 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294767296,
            200000,
            1000000,
        );
        pool::initialize_rewarder(user, pool, m1, 1 << 64, 1000000000);
        pool::initialize_rewarder(user, pool, m2, 2 << 64, 1000000000);
        pool::initialize_rewarder(user, pool, m3, 3 << 64, 1000000000);

        set_block_info(12, 1000);
        collect_reward(user, position_1, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_1, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_2, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_3, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        let position_4 = open_position_with_liquidity(
            user,
            pool,
            &pmint_ref1,
            &pmint_ref2,
            4294667296,
            300000,
            80000000,
        );
        swap(user, pool, &pmint_ref1, &pmint_ref2, false, true, 200000, max_sqrt_price());
        set_block_info(12, 1000 * 2);
        remove_liquidity(user, pool, position_1, 500000);
        swap(user, pool, &pmint_ref1, &pmint_ref2, false, true, 200000, max_sqrt_price());
        collect_reward(user, position_1, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_2, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_3, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_4, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        set_block_info(12, 1000 * 3);
        remove_liquidity(user, pool, position_2, 300000);
        add_liquidity(pool, &pmint_ref1, &pmint_ref2, position_1, 1000000);
        set_block_info(12, 1000 * 4);
        collect_reward(user, position_2, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        swap(user, pool, &pmint_ref1, &pmint_ref2, true, true, 300000, min_sqrt_price());
        set_block_info(12, 1000 * 5);
        collect_reward(user, position_3, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        set_block_info(12, 1000 * 6);
        add_liquidity(pool, &pmint_ref1, &pmint_ref2, position_3, 2000000);
        set_block_info(12, 1000 * 7);
        collect_reward(user, position_2, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_3, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_4, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        remove_liquidity(user, pool, position_3, 800000);
        collect_reward(user, position_3, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        swap(user, pool, &pmint_ref1, &pmint_ref2, true, true, 30000000, min_sqrt_price());
        add_liquidity(pool, &pmint_ref1, &pmint_ref2, position_2, 2000000);
        swap(user, pool, &pmint_ref1, &pmint_ref2, true, true, 300000, min_sqrt_price());
        collect_reward(user, position_2, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        swap(user, pool, &pmint_ref1, &pmint_ref2, false, true, 200000, max_sqrt_price());
        set_block_info(12, 1000 * 8);
        swap(user, pool, &pmint_ref1, &pmint_ref2, false, true, 200000, max_sqrt_price());
        swap(user, pool, &pmint_ref1, &pmint_ref2, true, true, 30000000, min_sqrt_price());
        set_block_info(12, 1000 * 9);
        swap(user, pool, &pmint_ref1, &pmint_ref2, true, false, 20000000, min_sqrt_price());


        collect_reward(user, position_1, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_2, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_3, &mut receipt_c, &mut receipt_d, &mut receipt_e);
        collect_reward(user, position_4, &mut receipt_c, &mut receipt_d, &mut receipt_e);


        assert!(
            fungible_asset::amount(&receipt_c) + primary_fungible_store::balance(vault_address(), m1) == 100000000,
            0
        );
        assert!(
            fungible_asset::amount(&receipt_d) + primary_fungible_store::balance(vault_address(), m2) == 100000000,
            0
        );
        assert!(
            fungible_asset::amount(&receipt_e) + primary_fungible_store::balance(vault_address(), m3) == 100000000,
            0
        );
        primary_fungible_store::deposit(signer::address_of(user), receipt_c);
        primary_fungible_store::deposit(signer::address_of(user), receipt_d);
        primary_fungible_store::deposit(signer::address_of(user), receipt_e);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_rewards_end_time(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );


        let (metadata_a, _) = pool_metadata(pool);
        let user_asset = fungible_asset::zero(metadata_a);

        pool::initialize_rewarder(user, pool, metadata_a, 0, 0);
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        pool::update_emission(user, pool, metadata_a, 2 << 64, 10000);

        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            1000000,
        );
        set_block_info(12, 12000);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 10000 * 2 - 1, 0);
        fungible_asset::merge(&mut user_asset, rewarder_balance);
        assert!(
            fungible_asset::amount(&user_asset) + primary_fungible_store::balance(
                vault_address(),
                metadata_a
            ) == 100000000
            , 1);
        primary_fungible_store::deposit(signer::address_of(user), user_asset);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_rewards_end_time_1(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );


        let (metadata_a, _) = pool_metadata(pool);
        let user_asset = fungible_asset::zero(metadata_a);

        pool::initialize_rewarder(user, pool, metadata_a, 0, 0);
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        pool::update_emission(user, pool, metadata_a, 2 << 64, 10000);

        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            1000000,
        );
        set_block_info(12, 6000);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 6000 * 2 - 1, 0);
        fungible_asset::merge(&mut user_asset, rewarder_balance);

        set_block_info(12, 6000 * 2);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 4000 * 2 - 1, 0);
        fungible_asset::merge(&mut user_asset, rewarder_balance);
        assert!(
            fungible_asset::amount(&user_asset) + primary_fungible_store::balance(
                vault_address(),
                metadata_a
            ) == 100000000
            , 1);

        set_block_info(12, 6000 * 3);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 0, 0);
        fungible_asset::destroy_zero(rewarder_balance);
        primary_fungible_store::deposit(signer::address_of(user), user_asset);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_rewards_end_time_2(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        rewarder::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 4);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            5,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );


        let (metadata_a, _) = pool_metadata(pool);
        let user_asset = fungible_asset::zero(metadata_a);

        pool::initialize_rewarder(user, pool, metadata_a, 0, 0);
        primary_fungible_store::deposit(rewarder::vault_address(), fungible_asset::mint(&mint_ref1, 100000000));
        pool::update_emission(user, pool, metadata_a, 2 << 64, 10000);

        let position_1 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            1000000,
        );
        set_block_info(12, 6000);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 6000 * 2 - 1, 0);
        fungible_asset::merge(&mut user_asset, rewarder_balance);

        let position_2 = open_position_with_liquidity(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            4294966296,
            1000,
            3000000,
        );
        set_block_info(12, 6000 * 2);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 1000 * 2 - 1, 0);
        fungible_asset::merge(&mut user_asset, rewarder_balance);

        let reward_balances = pool::collect_rewards(
            user,
            position_2,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 3000 * 2 - 1, 0);
        fungible_asset::merge(&mut user_asset, rewarder_balance);
        assert!(
            fungible_asset::amount(&user_asset) + primary_fungible_store::balance(
                vault_address(),
                metadata_a
            ) == 100000000
            , 1);

        set_block_info(12, 6000 * 3);
        let reward_balances = pool::collect_rewards(
            user,
            position_1,
        );
        let rewarder_balance = vector::pop_back(&mut reward_balances);
        vector::destroy_empty(reward_balances);
        assert!(fungible_asset::amount(&rewarder_balance) == 0, 0);
        fungible_asset::destroy_zero(rewarder_balance);
        primary_fungible_store::deposit(signer::address_of(user), user_asset);
    }

    fun collect_reward(
        user: &signer,
        position: Object<PositionNft>,
        receipt_a: &mut FungibleAsset,
        receipt_b: &mut FungibleAsset,
        receipt_c: &mut FungibleAsset,
    ) {
        let reward = pool::collect_rewards(
            user,
            position
        );
        fungible_asset::merge(receipt_c, vector::pop_back(&mut reward));
        fungible_asset::merge(receipt_b, vector::pop_back(&mut reward));
        fungible_asset::merge(receipt_a, vector::pop_back(&mut reward));
        vector::destroy_empty(reward);
    }
}