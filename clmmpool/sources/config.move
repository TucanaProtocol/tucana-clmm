// Copyright (c) Tucana Technology Limited

/// The config module is used for manage the `protocol_fee`, acl roles and fee_tiers of the tucana clmm protocol.
/// The `protocol_fee` is the protocol fee rate, it will be charged when user swap token.
/// The `fee_tiers` is a map, the key is the tick spacing, the value is the FeeTier. the fee_rate of FeeTier can be same for
/// different tick_spacing and can be updated.
/// For different types of pair, we can use different tick spacing. Basically, for stable pair we can use small tick
/// spacing, for volatile pair we can use large tick spacing.
/// the fee generated of a swap is calculated by the following formula:
/// total_fee = fee_rate * swap_in_amount.
/// protocol_fee = total_fee * protocol_fee_rate / 1000000
/// lp_fee = total_fee - protocol_fee
/// Also, the acl roles is managed by this module, the roles is used for control the access of the tucana clmmpool
/// protocol.
/// Currently, we have 5 roles:
/// 1. PoolManager: The pool manager can update pool fee rate, pause and unpause the pool.
/// 2. FeeTierManager: The fee tier manager can add/remove fee tier, update fee tier fee rate.
/// 3. ClaimProtocolFee: The claim protocol fee can claim the protocol fee.
/// 4. PartnerManager: The partner manager can add/remove partner, update partner fee rate.
/// 5. RewarderManager: The rewarder manager can add/remove rewarder, update rewarder fee rate.
/// 6. Admin: The admin can add/remove acl role and member.
module tucana_clmm::config {
    use tucana_std::acl;

    use initia_std::simple_map::SimpleMap;

    /// Max swap fee rate(100000 = 200000/1000000 = 20%)
    const MAX_FEE_RATE: u64 = 200000;
    const MAX_PROTOCOL_FEE_RATE: u64 = 3000;
    const DEFAULT_PROTOCOL_FEE_RATE: u64 = 2000;

    /// Clmmpools acl roles
    const ACL_POOL_MANAGER: u8 = 0;
    const ACL_FEE_TIER_MANAGER: u8 = 1;
    const ACL_CLAIM_PROTOCOL_FEE: u8 = 2;
    const ACL_PARTNER_MANAGER: u8 = 3;
    const ACL_REWARDER_MANAGER: u8 = 4;
    const ACL_ADMIN: u8 = 127;

    // =============== Errors =================

    const EFeeTierAlreadyExist: u64 = 1;
    const EFeeTierNotFound: u64 = 2;
    const EInvalidFeeRate: u64 = 3;
    const EInvalidProtocolFeeRate: u64 = 4;
    const ENoPoolManagerPemission: u64 = 5;
    const ENoFeeTierManagerPermission: u64 = 6;
    const ENoPartnerManagerPermission: u64 = 7;
    const ENoRewarderManagerPermission: u64 = 8;
    const ENoProtocolFeeClaimPermission: u64 = 9;
    const ENotAdminPermission: u64 = 10;
    const EIllegalOperation: u64 = 11;

    // =============== Structs =================

    /// The clmmpools fee tier data
    struct FeeTier has store, copy, drop {
        /// The tick spacing
        tick_spacing: u32,

        /// The default fee rate
        fee_rate: u64,
    }

    struct Config has key {
        /// `protocol_fee_rate` The protocol fee rate
        protocol_fee_rate: u64,
        /// 'fee_tiers' The Clmmpools fee tier map
        fee_tiers: SimpleMap<u32, FeeTier>,
        /// `acl` The Clmmpools ACL
        acl: acl::ACL,
    }

    // === Events ===
    #[event]
    /// Emit when update the FeeTier fee rate
    struct UpdateFeeRateEvent has drop, store {
        old_fee_rate: u64,
        new_fee_rate: u64,
    }

    #[event]
    /// Emit when add fee_tier
    struct AddFeeTierEvent has drop, store {
        tick_spacing: u32,
        fee_rate: u64,
    }

    #[event]
    /// Emit when update fee_tier
    struct UpdateFeeTierEvent has drop, store {
        tick_spacing: u32,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }

    #[event]
    /// Emit when delete fee_tier
    struct DeleteFeeTierEvent has drop, store {
        tick_spacing: u32,
        fee_rate: u64,
    }

    #[event]
    /// Emit when set roles
    struct SetRolesEvent has drop, store {
        member: address,
        roles: u128,
    }

    #[event]
    /// Emit when add member a role
    struct AddRoleEvent has drop, store {
        member: address,
        role: u8,
    }

    #[event]
    /// Emit when remove member a role
    struct RemoveRoleEvent has drop, store {
        member: address,
        role: u8
    }

    #[event]
    /// Emit when remove member
    struct RemoveMemberEvent has drop, store {
        member: address,
    }

    // === Functions ===
    /// init `Config`
    fun init_module(_tucana: &signer) {
        abort 0
    }

    /// Update the protocol fee rate
    /// Params
    ///     - manager: The pool manager signer
    ///     - protocol_fee_rate: The new protocol fee rate
    public entry fun update_protocol_fee_rate(
        _manager: &signer,
        _protocol_fee_rate: u64,
    )  {
        abort 0
    }

    /// Add a fee tier
    /// Params
    ///     - manager: The manager signer
    ///     - tick_spacing: The tick spacing
    ///     - fee_rate: The fee rate
    public entry fun add_fee_tier(
        _manager: &signer,
        _tick_spacing: u32,
        _fee_rate: u64,
    )  {
        abort 0
    }

    //// Delete a fee tier by `tick_spacing`.
    /// Params
    ///     - manager: The manager signer
    ///     - tick_spacing: The tick spacing
    public entry fun delete_fee_tier(
        _manager: &signer,
        _tick_spacing: u32,
    )  {
        abort 0
    }

    /// Update the fee rate of a FeeTier by `tick_spacing`.
    /// Params
    ///     - manager: The manager signer
    ///     - tick_spacing: The tick spacing
    ///     - new_fee_rate: The new fee rate
    public entry fun update_fee_tier(
        _manager: &signer,
        _tick_spacing: u32,
        _new_fee_rate: u64,
    )  {
        abort 0
    }

    /// Set roles for member.
    /// Params
    ///     - manager: The manager signer
    ///     - member: The member address
    ///     - roles: The roles
    public entry fun set_roles(
        _manager: &signer,
        _member: address,
        _roles: u128
    )  {
        abort 0
    }

    /// Add a role for member.
    /// Params
    ///     - manager: The manager signer
    ///     - member: The member address
    ///     - role: The role
    public entry fun add_role(
        _manager: &signer,
        _member: address,
        _role: u8
    )  {
        abort 0
    }

    /// Remove a role for member.
    /// Params
    ///     - manager: The manager signer
    ///     - member: The member address
    ///     - role: The role
    public entry fun remove_role(
        _manager: &signer,
        _member: address,
        _role: u8
    )  {
        abort 0
    }

    /// Remove a member from ACL.
    /// Params
    ///     - manager: The manager signer
    ///     - member: The member address
    public entry fun remove_member(
        _manager: &signer,
        _member: address
    )  {
        abort 0
    }

    /// Check member has pool manager role
    public fun check_pool_manager_role(_manager: &signer)  {
        abort 0
    }

    /// Check member has fee tier manager role
    public fun check_fee_tier_manager_role(_manager: &signer)  {
        abort 0
    }

    /// Check member has protocol fee claim role
    public fun check_protocol_fee_claim_role(_manager: &signer)  {
        abort 0
    }

    /// Check member has partner manager role.
    public fun check_partner_manager_role(_manager: &signer)  {
        abort 0
    }

    /// Check member has rewarder manager role.
    public fun check_rewarder_manager_role(_manager: &signer)  {
        abort 0
    }

    /// Check member has admin role.
    public fun check_admin_role(_manager: &signer)  {
        abort 0
    }

    /// Get member has pool manager role or not.
    public fun has_pool_manager_role(
        _account: &signer,
    ): bool  {
        abort 0
    }

    #[view]
    /// Get all members in ACL.
    public fun get_members(): vector<acl::Member>  {
        abort 0
    }

    #[view]
    /// Get the protocol fee rate
    public fun get_protocol_fee_rate(): u64  {
        abort 0
    }

    #[view]
    /// Get FeeTier by tick_spacing
    public fun get_fee_tier(_tick_spacing: u32): FeeTier  {
        abort 0
    }

    #[view]
    /// Get all FeeTiers
    public fun get_fee_tiers(): SimpleMap<u32, FeeTier>  {
        abort 0
    }

    #[view]
    /// Get fee rate by tick spacing
    public fun get_fee_rate(
        _tick_spacing: u32,
    ): u64  {
        abort 0
    }

    #[view]
    /// Get the max fee rate
    public fun max_fee_rate(): u64 {
        MAX_FEE_RATE
    }

    #[view]
    /// Get the max protocol fee rate
    public fun max_protocol_fee_rate(): u64 {
        MAX_PROTOCOL_FEE_RATE
    }
}
