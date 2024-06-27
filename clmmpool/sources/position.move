// Copyright (c) Tucana Technology Limited

/// The `position` module is designed for the convenience of the `Pool`'s position and all `position` related
/// operations are completed by this module.

/// `clmmpool` specifies the ownership of the `position` through an `Object` named `position_nft`,
/// rather than a wallet address. This means that whoever owns the `position_nft` owns the position it holds.
/// This also means that `clmmpool`'s `position` can be transferred between users freely.
///
/// Each clmmpool is related to a NFT Collection, and positions under this pool is included in this collection.
module tucana_clmm::position {
    use std::string::{Self, String};

    use initia_std::collection::{MutatorRef};
    use initia_std::fungible_asset::Metadata;
    use initia_std::nft;
    use initia_std::object::{Object};

    use tucana_std::i32::{I32};


    const DEFAULT_POSITION_URI: vector<u8> = b"https://usw2bfwyjaizubsnw7kcwtpur5mdqcs54wdlnop7zp7qfo5qvmna.arweave.net/pK2glthIEZoGTbfUK030j1g4Cl3lhra5_8v_Aruwqxo";
    const DEFAULT_COLLECTION_URI: vector<u8> = b"";

    // =============== Errors =================

    const EFeeOwnedOverflow: u64 = 1;
    const ERewardOwnedOverflow: u64 = 2;
    const EInvalidPositionTickRange: u64 = 3;
    const EPositionIsNotEmpty: u64 = 4;
    const ELiquidityChangeOverflow: u64 = 5;
    const ELiquidityChangeUnderflow: u64 = 6;
    const ENotPositionCollectionOwner: u64 = 7;
    const ENotPositionCreator: u64 = 8;

    // =============== Structs =================

    /// `PositionNftCollection` Stores into NFT Collection Object
    struct PositionNftCollection has key {
        _pool_name: String,
        _mutator_ref: MutatorRef,
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32,
        _position_index: u64,
        _position_uri: String,
    }

    /// The Tucana_clmm pool's position.
    struct PositionNft has key, store {
        _mutator_ref: nft::MutatorRef,
        _burn_ref: nft::BurnRef,
        _metadata: PositionMetadata,
        _rewards: vector<PositionReward>,
    }

    struct PositionMetadata has store, copy, drop {
        _pool_id: address,
        _liquidity: u128,
        _tick_lower_index: I32,
        _tick_upper_index: I32,
        _fee_growth_inside_a: u128,
        _fee_growth_inside_b: u128,
        _fee_owned_a: u64,
        _fee_owned_b: u64,
    }

    /// The Position's rewarder
    struct PositionReward has drop, copy, store {
        _growth_inside: u128,
        _amount_owned: u64,
    }

    /// New `PositionNftCollection`
    public fun new(
        _pool_signer: &signer,
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32,
        _position_uri: String,
    ): Object<PositionNftCollection> {
        abort 0
    }

    public fun pool_name(
        _metadata_a: Object<Metadata>,
        _metadata_b: Object<Metadata>,
        _tick_spacing: u32
    ): String {
        abort 0
    }

    public fun collection_name(
        _pool_name: String
    ): String {
        abort 0
    }

    public fun default_collection_description(
        _pool_name: String,
    ): String {
        abort 0
    }

    public fun default_collection_uri(): String {
        string::utf8(DEFAULT_COLLECTION_URI)
    }

    public fun default_position_uri(): String {
        string::utf8(DEFAULT_COLLECTION_URI)
    }

    public fun default_position_description(
        _pool_name: String,
        _index: u64
    ): String {
        abort 0
    }

    public fun position_token_id(_pool_name: String, _index: u64): String {
        abort 0
    }

    /// Open a position
    /// Mint and return Position NFT.
    public fun open_position(
        _pool_signer: &signer,
        _collection: Object<PositionNftCollection>,
        _tick_lower_index: I32,
        _tick_upper_index: I32,
    ): Object<PositionNft> {
        abort 0
    }

    /// Close the position, and burn the position nft.
    public fun close_position(
        _pool_signer: &signer,
        _position: Object<PositionNft>
    )  {
        abort 0
    }

    /// Increase liquidity from position.
    /// Params
    ///     - position_nft: Object<PositionNFT>
    ///     - delta_liquidity: the liquidity to increase.
    ///     - fee_growth_inside_a: the latest position range fee_growth_inside_a.
    ///     - fee_growth_inside_b: the latest position range fee_growth_inside_b.
    ///     - rewards_growth_inside: the latest position range rewards_growth_inside.
    public fun increase_liquidity(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
        _delta_liquidity: u128,
        _fee_growth_inside_a: u128,
        _fee_growth_inside_b: u128,
        _rewards_growth_inside: vector<u128>
    ): u128  {
        abort 0
    }

    /// Decrease liquidity from position.
    /// Params
    ///     - position_nft: Position
    ///     - delta_liquidity: the liquidity to decrease, which should be less than position.liquidity.
    ///     - fee_growth_inside_a: the latest position range fee_growth_inside_a.
    ///     - fee_growth_inside_b: the latest position range fee_growth_inside_b.
    ///     - rewards_growth_inside: the latest position range rewards_growth_inside.
    public fun decrease_liquidity(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
        _delta_liquidity: u128,
        _fee_growth_inside_a: u128,
        _fee_growth_inside_b: u128,
        _rewards_growth_inside: vector<u128>
    ): u128  {
        abort 0
    }

    /// Update `PositionNFT` fee, return the fee_owned.
    /// Params
    ///     - position_id: Object<PositionNFT>
    ///     - fee_growth_inside_a: latest position fee growth_inside a
    ///     - fee_growth_inside_b: latest position fee growth_inside b
    public fun update_fee(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
        _fee_growth_inside_a: u128,
        _fee_growth_inside_b: u128
    ): (u64, u64)  {
        abort 0
    }

    /// Update `PositionNFT` rewards, return the amount_owned vector.
    /// Params
    ///     - position_id: position nft id
    ///     - rewards_growth_inside: vector of latest position rewards growth_inside
    public fun update_rewards(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
        _rewards_growth_inside: vector<u128>,
    ): vector<u64>  {
        abort 0
    }

    /// Update `PositionNFT` fee, reset the fee_owned_a and fee_owned_b and return the amount_owned.
    /// Params
    ///     - position_id: position nft id
    ///     - fee_growth_inside_a: latest position fee_growth_inside_a
    ///     - fee_growth_inside_b: latest position fee_growth_inside_b
    public fun update_and_reset_fee(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
        _fee_growth_inside_a: u128,
        _fee_growth_inside_b: u128
    ): (u64, u64)  {
        abort 0
    }

    /// Update `PositionNFT` rewards
    /// Reset the amount_owned to 0
    /// Return the amount_owned
    public fun update_and_reset_rewards(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
        _rewards_growth_inside: vector<u128>,
    ): vector<u64>  {
        abort 0
    }

    /// Reset the fee's amount owned to 0 and return the fee amount owned.
    public fun reset_fee(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
    ): (u64, u64)  {
        abort 0
    }

    /// Reset the rewarder's amount owned to 0 and return the reward num owned.
    public fun reset_rewarder(
        _pool_signer: &signer,
        _position: Object<PositionNft>,
    ): vector<u64>  {
        abort 0
    }

    #[view]
    /// the inited reward count in `PositionNFT`.
    public fun inited_rewards_count(
        _position: Object<PositionNft>,
    ): u64  {
        abort 0
    }

    #[view]
    /// Returns the amount of rewards owned by the position.
    public fun rewards_amount_owned(_position: Object<PositionNft>): vector<u64>  {
        abort 0
    }

    #[view]
    public fun pool_address(_position: Object<PositionNft>): address {
        abort 0
    }

    #[view]
    public fun position_metadata(_position: Object<PositionNft>): PositionMetadata  {
        abort 0
    }

    public fun position_tick_range(_metadata: &PositionMetadata): (I32, I32) {
        abort 0
    }

    public fun position_liquidity(_metadata: &PositionMetadata): u128 {
        abort 0
    }

    public fun position_fee_growth_inside(_metadata: &PositionMetadata): (u128, u128) {
        abort 0
    }

    public fun position_fee_owned(_metadata: &PositionMetadata): (u64, u64) {
        abort 0
    }

    public fun position_rewards(_position: Object<PositionNft>): vector<PositionReward>  {
        abort 0
    }

    /// Check if a position tick range is valid.
    /// 1. lower < upper
    /// 2. (lower >= min_tick) && (upper <= max_tick)
    /// 3. (lower % tick_spacing == 0) && (upper % tick_spacing == 0)
    public fun check_position_tick_range(_lower: I32, _upper: I32, _tick_spacing: u32) {
        abort 0
    }

    public fun is_position_empty(_position: Object<PositionNft>): bool  {
        abort 0
    }
}

