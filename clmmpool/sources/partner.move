// Copyright (c) Tucana Technology Limited

/// The "Partner" module introduces the "Partner" object.
/// When a partner engages in a swap transaction, they provide this object and are entitled to receive a portion of the corresponding swap fee that is allocated to them.
module tucana_clmm::partner {
    use std::string::{String};

    use initia_std::object::{ExtendRef, Object};
    use initia_std::simple_map;
    use initia_std::fungible_asset::{FungibleAsset, Metadata};



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
        _manager: &signer,
        _name: String,
        _ref_fee_rate: u64,
        _start_time: u64,
        _end_time: u64,
        _owner: address,
    ) {
        abort 0
    }

    /// Update partner ref fee rate.
    /// Params
    ///     - partner: Object Partner
    ///     - new_fee_rate
    public entry fun update_ref_fee_rate(
        _manager: &signer,
        _partner: Object<Partner>,
        _new_fee_rate: u64,
    ) {
        abort 0
    }

    /// Update partner time range.
    /// Params
    ///     - partner
    ///     - start_time
    ///     - end_time
    public entry fun update_time_range(
        _manager: &signer,
        _partner: Object<Partner>,
        _start_time: u64,
        _end_time: u64,
    ) {
        abort 0
    }

    /// The `PartnerCap` owner claim the parter fee by Object<Metadata>.
    /// Params
    ///     - partner
    ///     - metadata
    public entry fun claim_ref_fee(
        _account: &signer,
        _partner: Object<Partner>,
        _metadata: Object<Metadata>
    ) {
        abort 0
    }

    /// Receive ref fee.
    /// This method is called when swap and partner is provided.
    public fun receive_ref_fee(
        _partner: Object<Partner>,
        _fa: FungibleAsset
    ) {
        abort 0
    }

    #[view]
    /// Get partner name.
    public fun name(_partner: Object<Partner>): String {
        abort 0
    }

    #[view]
    /// get partner ref_fee_rate.
    public fun ref_fee_rate(_partner: Object<Partner>): u64 {
        abort 0
    }

    #[view]
    /// get partner start_time.
    public fun start_time(_partner: Object<Partner>): u64  {
        abort 0
    }

    #[view]
    /// get partner end_time.
    public fun end_time(_partner: Object<Partner>): u64 {
        abort 0
    }

    /// check the parter is valid or not, and return the partner ref_fee_rate.
    public fun current_ref_fee_rate(
        _partner: Object<Partner>,
    ): u64 {
        abort 0
    }
}
