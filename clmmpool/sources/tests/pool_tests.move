#[test_only]
module tucana_clmm::pool_tests {
    use std::option;
    use std::signer;
    use std::vector;
    use initia_std::collection;
    use initia_std::collection::Collection;
    use initia_std::fungible_asset;
    use initia_std::fungible_asset::MintRef;
    use initia_std::nft;
    use initia_std::object;
    use initia_std::object::{Object, object_address};
    use initia_std::primary_fungible_store;
    use tucana_clmm::router::remove_liquidity_with_option;
    use tucana_clmm::partner;
    use tucana_clmm::partner::Partner;
    use tucana_clmm::config;
    use tucana_std::full_math_u64;
    use tucana_std::i128;
    use tucana_clmm::clmm_math;
    use tucana_clmm::tick;
    use tucana_clmm::tick_math::{get_sqrt_price_at_tick, min_sqrt_price, max_sqrt_price};
    use tucana_clmm::position;
    use tucana_clmm::pool::{Pool, flash_swap, swap_pay_amount, repay_flash_swap, flash_swap_with_partner,
        ref_fee_amount
    };
    use tucana_clmm::pool;
    use tucana_clmm::position::{PositionNft, PositionNftCollection};
    use tucana_std::i32;
    use tucana_std::i32::I32;

    struct LPItem has copy, drop {
        liquidity: u128,
        tick_lower: I32,
        tick_upper: I32
    }

    fun lpitem(liquidity: u128, tick_lower: I32, tick_upper: I32): LPItem {
        LPItem {
            liquidity,
            tick_lower,
            tick_upper
        }
    }

    public fun pt(v: u32): I32 {
        i32::from(v)
    }

    public fun nt(v: u32): I32 {
        i32::neg_from(v)
    }

    #[test(user = @0x1234, mod = @0x1)]
    public fun test_open_position(user: &signer, mod: &signer) {
        let (pool, _, _) = pool::new_for_test(user, mod, 100, get_sqrt_price_at_tick(i32::zero()), 2000);
        open_position(user, pool, 4294966296, 1000, );
    }

    #[test(user = @0x1234, mod = @0x1)]
    public fun test_add_liquidity(user: &signer, mod: &signer) {
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            100,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (tick_lower, tick_upper) = (
            i32::neg_from(1000),
            i32::from(1000)
        );
        let position_nft = pool::open_position(
            user,
            pool,
            i32::as_u32(tick_lower),
            i32::as_u32(tick_upper),
        );
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_nft, 100000000, );
        add_liquidity_fix_coin(pool, &mint_ref1, &mint_ref2, position_nft, 100000, true);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_nft, 200000000);
        add_liquidity_fix_coin(pool, &mint_ref1, &mint_ref2, position_nft, 100000, false);
    }

    #[test(user = @0x1234, mod = @0x1)]
    public fun test_remove_liquidity_and_close(user: &signer, mod: &signer) {
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            100,
            get_sqrt_price_at_tick(i32::zero()),
            2000
        );
        let (tick_lower, tick_upper) = (
            i32::neg_from(1000),
            i32::from(1000)
        );
        let position_nft = pool::open_position(
            user,
            pool,
            i32::as_u32(tick_lower),
            i32::as_u32(tick_upper),
        );
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_nft, 100000000);
        remove_liquidity(user, pool, position_nft, 50000000);
        remove_liquidity(user, pool, position_nft, 50000000);
    }


    #[test(user = @tucana_clmm, mod = @0x1)]
    public fun test_swap(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 3);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            60,
            4201216077597414008,
            2000
        );
        // let config = config::new_global_config_for_test(test_scenario::ctx(test), 2000);
        //| pool | index |  liquidity  | tick_lower_index | tick_upper_index |
        //|------|-------|-------------|------------------|------------------|
        //|      |   1   |  244944594  |      -30840      |      -27960      |
        //|      |   2   |  323359200  |      -30840      |      -27960      |
        //|      |   8   |   1147824   |     -443580      |      443580      |
        //|      |  13   |  121909879  |      -33540      |      -25260      |
        //|      |  17   |   1285216   |      -34620      |      67320       |
        //|      |  20   |  321511631  |      -34620      |      67320       |
        //|      |  21   | 11555285940 |      52320       |      54840       |
        //|      |  23   |    14352    |      11400       |      113400      |
        //|      |  24   |   229090    |      -36780      |      67320       |
        //|      |  25   |  38848687   |      -34980      |      -32220      |
        //|      |  26   |   134514    |     -443580      |      443580      |
        //|      |  27   | 73580862370 |      -29760      |      -29640      |
        //|      |  28   | 7630712637  |      -29520      |      -29460      |
        //|      |  29   |   4410085   |      -33720      |      -15060      |
        //|      |  30   | 3468680112  |      -29700      |      -29460      |
        //|      |  31   |  22774837   |     -443580      |      443580      |
        //|      |  34   | 9236228715  |      -29700      |      -29460      |
        //|      |  35   |  23543990   |      -33720      |      -15060      |
        //|      |  36   |   2354399   |      -33720      |      -15060      |
        //|      |  37   | 3468680355  |      -29700      |      -29460      |
        //|      |  38   |  23543990   |      -33720      |      -15060      |

        let liquiditys = vector<LPItem>[
            lpitem(244944594, nt(30840), nt(27960)),
            lpitem(323359200, nt(30840), nt(27960)),
            lpitem(1147824, nt(443580), pt(443580)),
            lpitem(121909879, nt(33540), nt(25260)),
            lpitem(1285216, nt(34620), pt(67320)),
            lpitem(321511631, nt(34620), pt(67320)),
            lpitem(11555285940, pt(52320), pt(54840)),
            lpitem(14352, pt(11400), pt(113400)),
            lpitem(229090, nt(36780), pt(67320)),
            lpitem(38848687, nt(34980), nt(32220)),
            lpitem(134514, nt(443580), pt(443580)),
            lpitem(73580862370, nt(29760), nt(29640)),
            lpitem(7630712637, nt(29520), nt(29460)),
            lpitem(4410085, nt(33720), nt(15060)),
            lpitem(3468680112, nt(29700), nt(29460)),
            lpitem(22774837, nt(443580), pt(443580)),
            lpitem(9236228715, nt(29700), nt(29460)),
            lpitem(23543990, nt(33720), nt(15060)),
            lpitem(2354399, nt(33720), nt(15060)),
            lpitem(3468680355, nt(29700), nt(29460)),
            lpitem(23543990, nt(33720), nt(15060)),
        ];
        let i = 0;
        while (i < vector::length(&liquiditys)) {
            let LPItem { liquidity, tick_lower, tick_upper } = *vector::borrow(&liquiditys, i);
            add_liquidity_for_swap(user, pool, &mint_ref1, &mint_ref2, tick_lower, tick_upper, liquidity);
            i = i + 1;
        };

        let (recv_amount, pay_amount) = swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            10000000,
            min_sqrt_price(),
        );
        assert!(recv_amount == 517587, 0);
        assert!(pay_amount == 10000000, 0);
        let (recv_amount, pay_amount) = swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            10000000,
            min_sqrt_price(),
        );
        assert!(recv_amount == 517451, 0);
        assert!(pay_amount == 10000000, 0);

        let (recv_amount, pay_amount) = swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            100000000000,
            max_sqrt_price(),
        );
        assert!(recv_amount == 2620897394, 0);
        assert!(pay_amount == 100000000000, 0);
        assert!(pool::current_sqrt_price(pool) == 53088636778614969649700, 0);

        let partner = partner::create_partner_for_test(
            user,
            2000,
        );
        let (recv_amount, pay_amount) = swap_with_partner(
            user,
            pool,
            partner,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            1000000000,
            min_sqrt_price(),
        );
        assert!(recv_amount == 99685917468, 0);
        assert!(pay_amount == 1000000000, 0);
        assert!(pool::current_sqrt_price(pool) == 7226146395086366169, 0);
    }


    #[test(user = @tucana_clmm, mod = @0x1)]
    #[expected_failure(abort_code = tucana_clmm::pool::ENotEnoughLiquidity)]
    fun test_swap_to_target_price_expect_error_amount_out_is_zero(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 3);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            60,
            get_sqrt_price_at_tick(i32::from(0)),
            2000
        );

        let target_sqrt_price = get_sqrt_price_at_tick(i32::neg_from(1000));
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            1000000000,
            target_sqrt_price,
        );
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    #[expected_failure(abort_code = tucana_clmm::pool::EAmountIncorrect)]
    fun test_swap_to_target_price_expect_error_amount_in_incorrect(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            60,
            get_sqrt_price_at_tick(i32::from(0)),
            2000
        );

        let target_sqrt_price = get_sqrt_price_at_tick(i32::neg_from(1000));
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            0,
            target_sqrt_price,
        );
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_collect_fee(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            60,
            get_sqrt_price_at_tick(i32::from(0)),
            2000
        );
        let position_1 = open_position(user, pool, 4294965496, 1800);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_1, 100000000);
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            max_sqrt_price(),
        );
        let need_fee_b = ((((1000000 * 2000) / 1000000) * 8000) / 10000) - 1;
        let (fee_a, fee_b) = pool::collect_fee(user, position_1, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == need_fee_b, 0);
        fungible_asset::destroy_zero(fee_a);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);

        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            max_sqrt_price(),
        );
        let need_fee_b = ((((1000000 * 2000) / 1000000) * 8000) / 10000) - 1;
        let (calculate_fee_a, calculate_fee_b) = pool::calculate_and_update_fee(position_1);
        let (fee_a, fee_b) = pool::collect_fee(user, position_1, true);
        assert!(fungible_asset::amount(&fee_a) == calculate_fee_a, 0);
        assert!(fungible_asset::amount(&fee_b) == calculate_fee_b, 0);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == need_fee_b, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);

        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            1000000,
            min_sqrt_price(),
        );
        let need_fee_a = ((((1000000 * 2000) / 1000000) * 8000) / 10000) - 1;
        let (fee_a, fee_b) = pool::collect_fee(user, position_1, true);
        assert!(fungible_asset::amount(&fee_a) == need_fee_a, 0);
        assert!(fungible_asset::amount(&fee_b) == 0, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_a);
        fungible_asset::destroy_zero(fee_b);

        let position_2 = open_position(user, pool, 4294966096, 1200);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_1, 100000000);
        let (fee_a, fee_b) = pool::collect_fee(user, position_2, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 0, 0);
        fungible_asset::destroy_zero(fee_a);
        fungible_asset::destroy_zero(fee_b);
    }


    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_collect_fee_full_range(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            2,
            get_sqrt_price_at_tick(i32::from(0)),
            2000
        );
        let (lower, upper) = (4294523660, 443636);
        let position_0 = open_position(user, pool, lower, upper);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_0, 1);
        remove_liquidity(user, pool, position_0, 1);

        let position_1 = open_position(user, pool, 4294964896, 2400);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_1, 100000000);
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            max_sqrt_price(),
        );
        let (fee_a, fee_b) = pool::collect_fee(user, position_1, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 1599, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);

        let position_2 = open_position(user, pool, lower, upper);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_2, 100000000);
        let (fee_a, fee_b) = pool::collect_fee(user, position_2, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 0, 0);
        fungible_asset::destroy_zero(fee_a);
        fungible_asset::destroy_zero(fee_b);
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            max_sqrt_price(),
        );
        let (fee_a, fee_b) = pool::collect_fee(user, position_2, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 799, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);
        let (fee_a, fee_b) = pool::collect_fee(user, position_1, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 799, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);

        let position_3 = open_position(user, pool, lower, upper);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_3, 200000000);
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            max_sqrt_price(),
        );
        let (fee_a, fee_b) = pool::collect_fee(user, position_1, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 399, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);
        let (fee_a, fee_b) = pool::collect_fee(user, position_2, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 399, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);
        let (fee_a, fee_b) = pool::collect_fee(user, position_3, true);
        assert!(fungible_asset::amount(&fee_a) == 0, 0);
        assert!(fungible_asset::amount(&fee_b) == 799, 0);
        primary_fungible_store::deposit(signer::address_of(user), fee_b);
        fungible_asset::destroy_zero(fee_a);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    fun test_remove_liquidity_with_option(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            2,
            get_sqrt_price_at_tick(i32::from(0)),
            2000
        );
        let (lower, upper) = (4294966296, 1000);
        let position_0 = open_position(user, pool, lower, upper);
        add_liquidity(pool, &mint_ref1, &mint_ref2, position_0, 1);
        let position_meta = position::position_metadata(position_0);
        let liquidity = position::position_liquidity(&position_meta);
        remove_liquidity_with_option(user, position_0, liquidity-1, 0, 0, option::some(false), option::some(false));
        let position_meta = position::position_metadata(position_0);
        position::position_liquidity(&position_meta);
    }

    public fun add_liquidity_for_swap(
        user: &signer,
        pool: Object<Pool>,
        mint_ref1: &MintRef,
        mint_ref2: &MintRef,
        tick_lower_idx: I32,
        tick_upper_idx: I32,
        liquidity: u128,
    ) {
        let position_nft = pool::open_position(
            user,
            pool,
            i32::as_u32(tick_lower_idx),
            i32::as_u32(tick_upper_idx),
        );
        add_liquidity(pool, mint_ref1, mint_ref2, position_nft, liquidity);
    }

    public fun open_position(user: &signer, pool: Object<Pool>, tick_lower: u32, tick_upper: u32): Object<PositionNft> {
        let position_nft = pool::open_position(user, pool, tick_lower, tick_upper);
        let pos_metadata = position::position_metadata(position_nft);
        let (tick_l, tick_u) = position::position_tick_range(&pos_metadata);
        assert!(i32::eq(tick_l, i32::from_u32(tick_lower)), 1);
        assert!(i32::eq(tick_u, i32::from_u32(tick_upper)), 1);
        assert!(position::position_liquidity(&pos_metadata) == 0, 0);
        let collection = pool::collection(pool);
        assert!(
            nft::collection_object(position_nft) == object::convert<PositionNftCollection, Collection>(collection),
            1
        );
        assert!(collection::uri(collection) == nft::uri(position_nft), 1);
        assert!(collection::creator(collection) == nft::creator(position_nft), 1);
        position_nft
    }

    public fun open_position_with_liquidity(
        user: &signer,
        pool: Object<Pool>,
        mint_ref1: &MintRef,
        mint_ref2: &MintRef,
        tick_lower: u32,
        tick_upper: u32,
        liquidity: u128,
    ): Object<PositionNft> {
        let position = open_position(user, pool, tick_lower, tick_upper);
        add_liquidity(pool, mint_ref1, mint_ref2, position, liquidity);
        position
    }

    public fun add_liquidity(
        pool: Object<Pool>,
        mint_ref1: &MintRef,
        mint_ref2: &MintRef,
        position_nft: Object<PositionNft>,
        liquidity: u128,
    ) {
        let pos_metadata = position::position_metadata(position_nft);
        let (tick_lower_idx, tick_upper_idx) = position::position_tick_range(&pos_metadata);
        let (before_balance_a, before_balance_b) = pool::balances(pool);
        let (before_tick_lower, before_tick_upper) = {
            (
                pool::copy_tick_with_default(pool, tick_lower_idx),
                pool::copy_tick_with_default(pool, tick_upper_idx)
            )
        };
        let before_nft_liquidity = position::position_liquidity(&pos_metadata);

        let (amount_a, amount_b) = clmm_math::get_amount_by_liquidity(
            tick_lower_idx,
            tick_upper_idx,
            pool::current_tick_index(pool),
            pool::current_sqrt_price(pool),
            liquidity,
            true
        );

        let offer_a = fungible_asset::mint(mint_ref1, amount_a);
        let offer_b = fungible_asset::mint(mint_ref2, amount_b);
        let receipt = pool::add_liquidity(
            position_nft,
            liquidity,
        );
        pool::repay_add_liquidity(receipt, offer_a, offer_b);

        // Check pool balances
        let (after_balance_a, after_balance_b) = pool::balances(pool);
        let (after_tick_lower, after_tick_upper) = (
            pool::borrow_tick(pool, tick_lower_idx),
            pool::borrow_tick(pool, tick_upper_idx)
        );

        assert!((after_balance_a - before_balance_a) == amount_a, 0);
        assert!((after_balance_b - before_balance_b) == amount_b, 0);

        // Check position
        let after_position_info = position::position_metadata(position_nft);
        assert!(before_nft_liquidity + liquidity == position::position_liquidity(&after_position_info), 0);

        // Check tick liquidity
        assert!(tick::liquidity_gross(&after_tick_lower) - tick::liquidity_gross(&before_tick_lower) == liquidity, 0);
        assert!(tick::liquidity_gross(&after_tick_upper) - tick::liquidity_gross(&before_tick_upper) == liquidity, 0);
        assert!(
            i128::as_u128(
                i128::sub(tick::liquidity_net(&after_tick_lower), tick::liquidity_net(&before_tick_lower))
            ) == liquidity,
            0
        );
        assert!(
            i128::as_u128(
                i128::sub(tick::liquidity_net(&before_tick_upper), tick::liquidity_net(&after_tick_upper))
            ) == liquidity,
            0
        );
    }

    public fun add_liquidity_fix_coin(
        pool: Object<Pool>,
        mint_ref1: &MintRef,
        mint_ref2: &MintRef,
        position_nft: Object<PositionNft>,
        amount: u64,
        fix_amount_a: bool,
    ) {
        let pos_metadata = position::position_metadata(position_nft);
        let (tick_lower_idx, tick_upper_idx) = position::position_tick_range(&pos_metadata);
        let (before_balance_a, before_balance_b) = pool::balances(pool);
        let (before_tick_lower, before_tick_upper) = {
            (
                pool::copy_tick_with_default(pool, tick_lower_idx),
                pool::copy_tick_with_default(pool, tick_upper_idx)
            )
        };
        let before_nft_liquidity = position::position_liquidity(&pos_metadata);

        let (liquidity, amount_a, amount_b) = clmm_math::get_liquidity_by_amount(
            tick_lower_idx,
            tick_upper_idx,
            pool::current_tick_index(pool),
            pool::current_sqrt_price(pool),
            amount,
            fix_amount_a
        );
        let offer_a = fungible_asset::mint(mint_ref1, amount_a);
        let offer_b = fungible_asset::mint(mint_ref2, amount_b);

        let receipt = pool::add_liquidity_fix_coin(
            position_nft,
            amount,
            fix_amount_a,
        );
        pool::repay_add_liquidity(receipt, offer_a, offer_b);

        // asset retunr amount is zero


        // Check pool balances
        let (after_balance_a, after_balance_b) = pool::balances(pool);
        let (after_tick_lower, after_tick_upper) = (
            pool::borrow_tick(pool, tick_lower_idx),
            pool::borrow_tick(pool, tick_upper_idx)
        );
        assert!((after_balance_a - before_balance_a) == amount_a, 0);
        assert!((after_balance_b - before_balance_b) == amount_b, 0);


        // Check position
        let after_position_info = position::position_metadata(position_nft);
        assert!(before_nft_liquidity + liquidity == position::position_liquidity(&after_position_info), 0);

        // Check tick liquidity
        assert!(tick::liquidity_gross(&after_tick_lower) - tick::liquidity_gross(&before_tick_lower) == liquidity, 0);
        assert!(tick::liquidity_gross(&after_tick_upper) - tick::liquidity_gross(&before_tick_upper) == liquidity, 0);
        assert!(
            i128::as_u128(
                i128::sub(tick::liquidity_net(&after_tick_lower), tick::liquidity_net(&before_tick_lower))
            ) == liquidity,
            0
        );
        assert!(
            i128::as_u128(
                i128::sub(tick::liquidity_net(&before_tick_upper), tick::liquidity_net(&after_tick_upper))
            ) == liquidity,
            0
        );
    }


    public fun remove_liquidity(
        user: &signer,
        pool: Object<Pool>,
        position_nft: Object<PositionNft>,
        delta_liquidity: u128,
    ): (u64, u64) {
        let (before_balance_a, before_balance_b) = pool::balances(pool);
        let before_pool_current_liqudity = pool::liquidity(pool);
        let pos_metadata = position::position_metadata(position_nft);
        let (tick_lower_idx, tick_upper_idx) = position::position_tick_range(&pos_metadata);
        let (before_tick_lower, before_tick_upper) = (
            pool::borrow_tick(pool, tick_lower_idx), pool::borrow_tick(pool, tick_upper_idx)
        );
        let (recv_a, recv_b) = pool::remove_liquidity(user, position_nft, delta_liquidity);


        // Check balances
        let (need_a, need_b) = clmm_math::get_amount_by_liquidity(
            tick_lower_idx,
            tick_upper_idx,
            pool::current_tick_index(pool),
            pool::current_sqrt_price(pool),
            delta_liquidity,
            false
        );
        assert!(need_a == fungible_asset::amount(&recv_a), 0);
        assert!(need_b == fungible_asset::amount(&recv_b), 0);
        let (after_balance_a, after_balance_b) = pool::balances(pool);
        assert!((before_balance_a - after_balance_a) == need_a, 0);
        assert!((before_balance_b - after_balance_b) == need_b, 0);

        // Check tick's liquidity gross and liquidity net.
        let (after_tick_lower, after_tick_upper) = {
            (
                pool::copy_tick_with_default(pool, tick_lower_idx),
                pool::copy_tick_with_default(pool, tick_upper_idx)
            )
        };
        assert!(
            (tick::liquidity_gross(&before_tick_lower) - tick::liquidity_gross(&after_tick_lower)) == delta_liquidity,
            0
        );
        assert!(
            (tick::liquidity_gross(&before_tick_upper) - tick::liquidity_gross(&after_tick_upper)) == delta_liquidity,
            0
        );
        assert!(
            i128::eq(
                i128::sub(tick::liquidity_net(&before_tick_lower), tick::liquidity_net(&after_tick_lower)),
                i128::from(delta_liquidity)
            ),
            0
        );
        assert!(
            i128::eq(
                i128::add(tick::liquidity_net(&before_tick_upper), i128::from(delta_liquidity)),
                tick::liquidity_net(&after_tick_upper)
            ),
            0
        );

        // Check pool's liquidity
        if (i32::gte(pool::current_tick_index(pool), tick_upper_idx)) {
            assert!(pool::liquidity(pool) == before_pool_current_liqudity, 0);
        } else if (i32::gte(pool::current_tick_index(pool), tick_lower_idx)) {
            assert!(pool::liquidity(pool) + delta_liquidity == before_pool_current_liqudity, 0);
        } else {
            assert!(pool::liquidity(pool) == before_pool_current_liqudity, 0);
        };
        primary_fungible_store::deposit(signer::address_of(user), recv_a);
        primary_fungible_store::deposit(signer::address_of(user), recv_b);
        (need_a, need_b)
    }

    public fun swap(
        user: &signer,
        pool: Object<Pool>,
        mint_ref1: &MintRef,
        mint_ref2: &MintRef,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        sqrt_price_limit: u128,
    ): (u64, u64) {
        let (before_balance_a, before_balance_b) = pool::balances(pool);
        let (before_protocol_fee_a, before_protocol_fee_b) = pool::protocol_fee(pool);


        let (recv_balance, receipt) = flash_swap(
            pool,
            a2b,
            by_amount_in,
            amount,
            sqrt_price_limit,
        );
        let pay_amount = swap_pay_amount(&receipt);
        let pay_balance = if (a2b) {
            fungible_asset::mint(mint_ref1, pay_amount)
        } else {
            fungible_asset::mint(mint_ref2, pay_amount)
        };
        let (pay_amount_a, pay_amount_b) = if (a2b) {
            (pay_amount, 0)
        }else {
            (0, pay_amount)
        };

        repay_flash_swap(
            receipt,
            pay_balance
        );

        // Check pool balance
        let (after_balance_a, after_balance_b) = pool::balances(pool);
        let recv_amount = if (a2b) {
            assert!(after_balance_a - before_balance_a == pay_amount_a, 0);
            assert!(before_balance_b - after_balance_b == fungible_asset::amount(&recv_balance), 0);
            let amount = fungible_asset::amount(&recv_balance);

            amount
        } else {
            assert!(after_balance_b - before_balance_b == pay_amount_b, 0);
            assert!(before_balance_a - after_balance_a == fungible_asset::amount(&recv_balance), 0);
            let amount = fungible_asset::amount(&recv_balance);
            amount
        };
        primary_fungible_store::deposit(signer::address_of(user), recv_balance);

        // Check protocol fee
        // Protocol fees are calculated for every step swap in the split, and due to rounding up,
        // the actual fees may be slightly higher than the result calculated directly through the protocol fee rate
        let fee_amount = full_math_u64::mul_div_ceil(
            pay_amount,
            pool::fee_rate(pool),
            clmm_math::fee_rate_denominator()
        );
        let expect_protocol_fee = full_math_u64::mul_div_ceil(fee_amount, config::get_protocol_fee_rate(), 10000);
        let (after_protocol_fee_a, after_protocol_fee_b) = pool::protocol_fee(pool);
        if (a2b) {
            assert!(after_protocol_fee_a - before_protocol_fee_a >= expect_protocol_fee, 0);
            assert!((after_protocol_fee_a - before_protocol_fee_a - expect_protocol_fee) <= 100, 0);
            assert!(after_protocol_fee_b - before_protocol_fee_b == 0, 0);
        } else {
            assert!(after_protocol_fee_a - before_protocol_fee_a == 0, 0);
            assert!(after_protocol_fee_b - before_protocol_fee_b >= expect_protocol_fee, 0);
            assert!((after_protocol_fee_b - before_protocol_fee_b - expect_protocol_fee) <= 100, 0);
        };

        (recv_amount, pay_amount)
    }

    public fun swap_with_partner(
        user: &signer,
        pool: Object<Pool>,
        partner: Object<Partner>,
        mint_ref1: &MintRef,
        mint_ref2: &MintRef,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        sqrt_price_limit: u128,
    ): (u64, u64) {
        let (before_balance_a, before_balance_b) = pool::balances(pool);
        let (metadata_a, metadata_b) = pool::pool_metadata(pool);

        let (before_protocol_fee_a, before_protocol_fee_b) = pool::protocol_fee(pool);
        let (before_ref_balance_a, before_ref_balance_b) = (
            primary_fungible_store::balance(object_address(partner), metadata_a),
            primary_fungible_store::balance(object_address(partner), metadata_b)
        );

        let (recv_balance, receipt) = flash_swap_with_partner(
            pool,
            partner,
            a2b,
            by_amount_in,
            amount,
            sqrt_price_limit,
        );
        let ref_fee_amount = ref_fee_amount(&receipt);
        let pay_amount = swap_pay_amount(&receipt);
        let pay_balance = if (a2b) {
            fungible_asset::mint(mint_ref1, pay_amount)
        } else {
            fungible_asset::mint(mint_ref2, pay_amount)
        };
        let (pay_amount_a, pay_amount_b) = if (a2b) {
            (pay_amount, 0)
        }else {
            (0, pay_amount)
        };

        repay_flash_swap(
            receipt,
            pay_balance
        );

        // Check pool balance
        let (after_balance_a, after_balance_b) = pool::balances(pool);
        let recv_amount = if (a2b) {
            assert!(after_balance_a - before_balance_a + ref_fee_amount == pay_amount_a, 0);
            assert!(before_balance_b - after_balance_b == fungible_asset::amount(&recv_balance), 0);
            let amount = fungible_asset::amount(&recv_balance);
            amount
        } else {
            assert!(after_balance_b - before_balance_b + ref_fee_amount == pay_amount_b, 0);
            assert!(before_balance_a - after_balance_a == fungible_asset::amount(&recv_balance), 0);
            let amount = fungible_asset::amount(&recv_balance);
            amount
        };
        primary_fungible_store::deposit(signer::address_of(user), recv_balance);
        // Check protocol fee
        // Protocol fees are calculated for every step swap in the split, and due to rounding up,
        // the actual fees may be slightly higher than the result calculated directly through the protocol fee rate
        let fee_amount = full_math_u64::mul_div_ceil(
            pay_amount,
            pool::fee_rate(pool),
            clmm_math::fee_rate_denominator()
        );
        let expect_protocol_fee = full_math_u64::mul_div_ceil(
            fee_amount,
            config::get_protocol_fee_rate(),
            10000
        ) - ref_fee_amount;
        let (after_protocol_fee_a, after_protocol_fee_b) = pool::protocol_fee(pool);
        let real_protocol_fee = if (a2b) {
            let real_protocol_fee = after_protocol_fee_a - before_protocol_fee_a;
            assert!(real_protocol_fee >= expect_protocol_fee, 0);
            assert!((real_protocol_fee - expect_protocol_fee) <= 100, 0);
            assert!(after_protocol_fee_b - before_protocol_fee_b == 0, 0);
            real_protocol_fee
        } else {
            let real_protocol_fee = after_protocol_fee_b - before_protocol_fee_b;
            assert!(real_protocol_fee >= expect_protocol_fee, 0);
            assert!((real_protocol_fee - expect_protocol_fee) <= 100, 0);
            assert!(after_protocol_fee_a - before_protocol_fee_a == 0, 0);
            real_protocol_fee
        };

        // Check ref fee
        let (after_ref_balance_a, after_ref_balance_b) = (
            primary_fungible_store::balance(object_address(partner), metadata_a),
            primary_fungible_store::balance(object_address(partner), metadata_b));
        assert!(
            ref_fee_amount == full_math_u64::mul_div_floor(
                (real_protocol_fee + ref_fee_amount),
                partner::ref_fee_rate(partner),
                10000
            ),
            0
        );
        if (a2b) {
            assert!((after_ref_balance_a - before_ref_balance_a) == ref_fee_amount, 0);
            assert!((after_ref_balance_b - before_ref_balance_b) == 0, 0);
        } else {
            assert!((after_ref_balance_a - before_ref_balance_a) == 0, 0);
            assert!((after_ref_balance_b - before_ref_balance_b) == ref_fee_amount, 0);
        };

        (recv_amount, pay_amount)
    }
}