#[test_only]
module tucana_clmm::swap_tests {

    use std::signer;
    use initia_std::block::set_block_info;
    use initia_std::debug;
    use tucana_clmm::tick_math::get_sqrt_price_at_tick;
    use tucana_clmm::tick_math;
    use tucana_clmm::rewarder;
    use tucana_std::i128;
    use tucana_std::i32;
    use tucana_clmm::pool_tests::{nt, pt, swap, add_liquidity_for_swap};
    use tucana_clmm::tick;
    use tucana_clmm::pool;
    use tucana_clmm::config;

    #[test(user = @tucana_clmm, mod = @0x1)]
    public fun test_swap_verify(user: &signer, mod: &signer) {
        //-----------------------------------------------------------------------------------------------------------------------------------------------------
        //|  index  |          sqrt_price           | liquidity_net  | liquidity_gross | fee_growth_outside_a | fee_growth_outside_b |    rewards_outside     |
        //|---------|-------------------------------|----------------|-----------------|----------------------|----------------------|------------------------|
        //| -443636 |          4295048016           |    3383805     |     3383805     |          0           |          0           |       [0, 0, 0]        |
        //|  -4056  |     15060840354818686363      |   1291105259   |   1291105259    |     35690725982      |    74254907353328    |          [0]           |
        //|  -1000  |     17547129613991598777      |   896544652    |    896544652    |     35690725982      |    74254907353328    |          [0]           |
        //|   -6    |     18441211157107643397      |   6668000044   |   6668000044    |          0           |          0           |           []           |
        //|   -4    |     18443055278223354162      |   6664722064   |   6664722064    |          0           |     221263904357     |           []           |
        //|   -2    |     18444899583751176498      | 8861984406924  |  8861984406924  |          0           |          0           |           []           |
        //|    2    |     18448588748116922571      |    -400039     |     400039      |          0           |     146569530227     |       [0, 0, 0]        |
        //|    4    |     18450433606991734263      | -8861984006885 |  8861984006885  |     35690725982      |     330892876818     |       [0, 0, 0]        |
        //|    6    |     18452278650352433436      |  -13332722108  |   13332722108   |     35690725982      |     478923680058     |       [0, 0, 0]        |
        //|   548   |     18959147107529850169      |   231964850    |    231964850    |    10060485047214    |    74928443098177    |          [0]           |
        //|   816   |     19214896586356138629      |    30594502    |    30594502     |    10060485047214    |    74928443098177    |          [0]           |
        //|   820   |     19218739757822375721      |   -30594502    |    30594502     |          0           |          0           |       [0, 0, 0]        |
        //|   910   |     19305414625256680593      |   -231964850   |    231964850    |          0           |          0           |       [0, 0, 0]        |
        //|   946   |     19340193924625646706      |  15313241696   |   15313241696   |     502682728422     |          0           | [27731076341762168138] |
        //|   948   |     19342127944018109271      |  131100125586  |  131100125586   |          0           |          0           |       [0, 0, 0]        |
        //|   956   |     19349865955800763602      | -131100125586  |  131100125586   |          0           |          0           |       [0, 0, 0]        |
        //|   960   |     19353736122490583312      |  -15313241696  |   15313241696   |          0           |          0           |       [0, 0, 0]        |
        //|  1000   |     19392480388906836277      |   -896544652   |    896544652    |          0           |          0           |       [0, 0, 0]        |
        //|  5010   |     23697637456172827896      |  -1291105259   |   1291105259    |          0           |          0           |       [0, 0, 0]        |
        //| 443636  | 79226673515401279992447579055 |    -3383805    |     3383805     |          0           |          0           |       [0, 0, 0]        |
        //-----------------------------------------------------------------------------------------------------------------------------------------------------

        config::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 3);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            2,
            19218706184437883591,
            2000
        );
        let (metadata_a, _metadata_b) = pool::pool_metadata(pool);

        let ticks = vector[
            tick::new_tick_for_test(nt(443636), i128::from(3383805), 3383805, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(
                nt(4056),
                i128::from(1291105259),
                1291105259,
                35690725982,
                74254907353328,
                vector[0]
            ),
            tick::new_tick_for_test(nt(1000), i128::from(896544652), 896544652, 35690725982, 74254907353328, vector[0]),
            tick::new_tick_for_test(nt(6), i128::from(6668000044), 6668000044, 0, 0, vector[]),
            tick::new_tick_for_test(nt(4), i128::from(6664722064), 6664722064, 0, 221263904357, vector[]),
            tick::new_tick_for_test(nt(2), i128::from(8861984406924), 8861984406924, 0, 0, vector[]),
            tick::new_tick_for_test(pt(2), i128::neg_from(400039), 400039, 0, 146569530227, vector[0, 0, 0]),
            tick::new_tick_for_test(
                pt(4),
                i128::neg_from(8861984006885),
                8861984006885,
                35690725982,
                330892876818,
                vector[0, 0, 0]
            ),
            tick::new_tick_for_test(
                pt(6),
                i128::neg_from(13332722108),
                13332722108,
                35690725982,
                478923680058,
                vector[0, 0, 0]
            ),
            tick::new_tick_for_test(
                pt(548),
                i128::from(231964850),
                231964850,
                10060485047214,
                74928443098177,
                vector[0]
            ),
            tick::new_tick_for_test(pt(816), i128::from(30594502), 30594502, 10060485047214, 74928443098177, vector[0]),
            tick::new_tick_for_test(pt(820), i128::neg_from(30594502), 30594502, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(pt(910), i128::neg_from(231964850), 231964850, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(
                pt(946),
                i128::from(15313241696),
                15313241696,
                502682728422,
                0,
                vector[27731076341762168138]
            ),
            tick::new_tick_for_test(pt(948), i128::from(131100125586), 131100125586, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(pt(956), i128::neg_from(131100125586), 131100125586, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(pt(960), i128::neg_from(15313241696), 15313241696, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(pt(1000), i128::neg_from(896544652), 896544652, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(pt(5010), i128::neg_from(1291105259), 1291105259, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(pt(443636), i128::neg_from(3383805), 3383805, 0, 0, vector[0, 0, 0]),
        ];
        let rewarders = vector[
            rewarder::new_rewarder_for_test(metadata_a, 2135039823346012918518, 27805703433573585662)
        ];
        pool::update_for_swap_test(
            pool,
            &mint_ref1,
            &mint_ref2,
            306402720,
            3045044692,
            2453593068,
            19218706184437883591,
            pt(819),
            10060485047214,
            74928443098177,
            605,
            13256,
            ticks,
            rewarders,
            1681893635
        );

        set_block_info(12, 1681910349);
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            9223372036854775807,
            11024038130778859745,
        );
        assert!(pool::current_sqrt_price(pool) == 11024038130778859745, 0);
    }


    #[test(user = @tucana_clmm, mod = @0x1)]
    public fun test_repair_tick_crossed_boudary_pool(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 3);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            2,
            get_sqrt_price_at_tick(i32::zero()),
            100
        );

        let ticks = vector[
            tick::new_tick_for_test(nt(443636), i128::from(0), 0, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(nt(36696), i128::from(1717314347), 1717314347, 0, 0, vector[0, 0, 0]),
            tick::new_tick_for_test(
                nt(18970),
                i128::neg_from(1717314347),
                1717314347,
                35690725982,
                74254907353328,
                vector[0]
            ),
            tick::new_tick_for_test(pt(443636), i128::from(0), 0, 0, 0, vector[0, 0, 0]),
        ];
        set_block_info(12, 1681910349);
        pool::update_for_swap_test(
            pool,
            &mint_ref1,
            &mint_ref2,
            6342726712,
            18214,
            0,
            4295048016,
            nt(443637),
            10060485047214,
            74928443098177,
            605,
            13256,
            ticks,
            vector[],
            1681893635
        );
        add_liquidity_for_swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            nt(443636),
            pt(443636),
            100,
        );

        //pool::repair_tick_crossed_bounday_pool(&admin_cap, &mut pool);
        //assert!(i32::eq(pool::current_tick_index(&pool), nt(36697)), 1);

        let (recv, pay) = swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            tick_math::max_sqrt_price(),
        );
        debug::print(&recv);
        assert!(recv == 429527739024, 0);
        assert!(pay == 1000000, 0);
    }

    #[test(user = @tucana_clmm, mod = @0x1)]
    public fun test_verify_tick_cross_boudary(user: &signer, mod: &signer) {
        config::init_module_for_test(user);
        config::add_role(user, signer::address_of(user), 3);
        let (pool, mint_ref1, mint_ref2) = pool::new_for_test(
            user,
            mod,
            2,
            19218706184437883591,
            2000
        );

        add_liquidity_for_swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            nt(10),
            pt(10),
            10000,
        );

        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            true,
            true,
            1000000,
            get_sqrt_price_at_tick(nt(10)),
        );
        assert!(i32::eq(pool::current_tick_index(pool), nt(11)), 0);
        swap(
            user,
            pool,
            &mint_ref1,
            &mint_ref2,
            false,
            true,
            1000000,
            get_sqrt_price_at_tick(pt(10)),
        );
        assert!(i32::eq(pool::current_tick_index(pool), pt(10)), 0);
    }
}
