// Copyright (c) Tucana Technology Limited

/// The "Partner" module introduces the "Partner" object.
/// When a partner engages in a swap transaction, they provide this object and are entitled to receive a portion of the corresponding swap fee that is allocated to them.
module tucana_clmm::partner {
    use std::signer::address_of;
    use std::string::{Self, String};

    use initia_std::block;
    use initia_std::object;
    use initia_std::object::{ExtendRef, Object, object_address};
    use initia_std::simple_map;
    use initia_std::event;
    use initia_std::fungible_asset::{FungibleAsset, Metadata};
    use initia_std::primary_fungible_store;

    use tucana_clmm::config::{check_partner_manager_role};


    const MAX_PARTNER_FEE_RATE: u64 = 10000;

    // =============== Errors =================

    const EPartnerAlreadyExist: u64 = 1;
    const EInvalidTime: u64 = 2;
    const EInvalidPartnerRefFeeRate: u64 = 3;
    const ENotPartnerOwner: u64 = 4;
    const EInvalidPartnerName: u64 = 5;

    // =============== Structs =================

    /// The partners is hold in SimpleMap.
    /// Key is partner name, value is partner object.
    struct Partners has key {
        partners: simple_map::SimpleMap<String, Object<Partner>>
    }

    /// Partner is used to store the partner info.
    /// The partner info include the partner name, ref fee rate, time range.
    struct Partner has key {
        extend_ref: ExtendRef,
        name: String,
        ref_fee_rate: u64,
        start_time: u64,
        end_time: u64,
    }

    // ============= Events =================

    #[event]
    /// Emit when create partner.
    struct CreatePartnerEvent has store, drop {
        owner: address,
        partner_addr: address,
        ref_fee_rate: u64,
        name: String,
        start_time: u64,
        end_time: u64,
    }

    #[event]
    /// Emit when update partner ref fee rate.
    struct UpdateRefFeeRateEvent has store, drop {
        partner_addr: address,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }

    #[event]
    /// Emit when update partner time range.
    struct UpdateTimeRangeEvent has store, drop {
        partner_addr: address,
        start_time: u64,
        end_time: u64,
    }

    #[event]
    /// Emit when receive ref fee.
    struct ReceiveRefFeeEvent has store, drop {
        partner_addr: address,
        amount: u64,
        metadata: Object<Metadata>,
    }

    #[event]
    /// Emit when claim ref fee.
    struct ClaimRefFeeEvent has store, drop {
        partner_addr: address,
        amount: u64,
        metadata: Object<Metadata>,
    }

    /// Create partner.
    /// Params
    ///     - name: the partner name.
    ///     - ref_fee_rate: the partner ref fee rate.
    ///     - start_time: the partner valid start time.
    ///     - end_time: the partner valid end time.
    ///     - owner: the partner cap owner.
    public entry fun create_partner(
        manager: &signer,
        name: String,
        ref_fee_rate: u64,
        start_time: u64,
        end_time: u64,
        owner: address,
    ) acquires Partners {
        abort 0
    }

    /// Update partner ref fee rate.
    /// Params
    ///     - partner: Object Partner
    ///     - new_fee_rate
    public entry fun update_ref_fee_rate(
        manager: &signer,
        partner: Object<Partner>,
        new_fee_rate: u64,
    ) acquires Partner {
        abort 0
    }

    /// Update partner time range.
    /// Params
    ///     - partner
    ///     - start_time
    ///     - end_time
    public entry fun update_time_range(
        manager: &signer,
        partner: Object<Partner>,
        start_time: u64,
        end_time: u64,
    ) acquires Partner {
        abort 0
    }

    /// The `PartnerCap` owner claim the parter fee by Object<Metadata>.
    /// Params
    ///     - partner
    ///     - metadata
    public entry fun claim_ref_fee(
        account: &signer,
        partner: Object<Partner>,
        metadata: Object<Metadata>
    ) acquires Partner {
        abort 0
    }

    /// Receive ref fee.
    /// This method is called when swap and partner is provided.
    public fun receive_ref_fee(
        partner: Object<Partner>,
        fa: FungibleAsset
    ) {
        abort 0
    }

    #[view]
    /// Get partner name.
    public fun name(partner: Object<Partner>): String acquires Partner {
        abort 0
    }

    #[view]
    /// get partner ref_fee_rate.
    public fun ref_fee_rate(partner: Object<Partner>): u64 acquires Partner {
        abort 0
    }

    #[view]
    /// get partner start_time.
    public fun start_time(partner: Object<Partner>): u64 acquires Partner {
        abort 0
    }

    #[view]
    /// get partner end_time.
    public fun end_time(partner: Object<Partner>): u64 acquires Partner {
        abort 0
    }

    /// check the parter is valid or not, and return the partner ref_fee_rate.
    public fun current_ref_fee_rate(
        partner: Object<Partner>,
    ): u64 acquires Partner {
        abort 0
    }
}
