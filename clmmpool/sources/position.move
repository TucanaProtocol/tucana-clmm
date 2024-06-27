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
    use std::vector;
    use std::option;
    use std::signer;
    use std::signer::address_of;

    use initia_std::collection;
    use initia_std::collection::{MutatorRef, Collection};
    use initia_std::fungible_asset;
    use initia_std::fungible_asset::Metadata;
    use initia_std::nft;
    use initia_std::nft::Nft;
    use initia_std::object;
    use initia_std::object::{Object, object_address, object_from_constructor_ref};
    use initia_std::royalty::Royalty;

    use tucana_std::i32::{Self, I32};
    use tucana_std::math_u128;
    use tucana_std::full_math_u128;
    use tucana_std::math_u64;
    use tucana_clmm::tick_math;


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
        pool_name: String,
        mutator_ref: MutatorRef,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32,
        position_index: u64,
        position_uri: String,
    }

    /// The Tucana_clmm pool's position.
    struct PositionNft has key, store {
        mutator_ref: nft::MutatorRef,
        burn_ref: nft::BurnRef,
        metadata: PositionMetadata,
        rewards: vector<PositionReward>,
    }

    struct PositionMetadata has store, copy, drop {
        pool_id: address,
        liquidity: u128,
        tick_lower_index: I32,
        tick_upper_index: I32,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128,
        fee_owned_a: u64,
        fee_owned_b: u64,
    }

    /// The Position's rewarder
    struct PositionReward has drop, copy, store {
        growth_inside: u128,
        amount_owned: u64,
    }

    /// New `PositionNftCollection`
    public fun new(
        pool_signer: &signer,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32,
        position_uri: String,
    ): Object<PositionNftCollection> {
        abort 0
    }

    public fun pool_name(
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        tick_spacing: u32
    ): String {
        abort 0
    }

    public fun collection_name(
        pool_name: String
    ): String {
        abort 0
    }

    public fun default_collection_description(
        pool_name: String,
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
        pool_name: String,
        index: u64
    ): String {
        abort 0
    }

    public fun position_token_id(pool_name: String, index: u64): String {
        abort 0
    }

    public fun update_position_uri(
        pool_signer: &signer,
        collection: Object<PositionNftCollection>,
        position_uri: String
    ) acquires PositionNftCollection {
        abort 0
    }

    /// Open a position
    /// Mint and return Position NFT.
    public fun open_position(
        pool_signer: &signer,
        collection: Object<PositionNftCollection>,
        tick_lower_index: I32,
        tick_upper_index: I32,
    ): Object<PositionNft> acquires PositionNftCollection {
        abort 0
    }

    /// Close the position, and burn the position nft.
    public fun close_position(
        pool_signer: &signer,
        position: Object<PositionNft>
    ) acquires PositionNft {
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
        pool_signer: &signer,
        position: Object<PositionNft>,
        delta_liquidity: u128,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128,
        rewards_growth_inside: vector<u128>
    ): u128 acquires PositionNft {
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
        pool_signer: &signer,
        position: Object<PositionNft>,
        delta_liquidity: u128,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128,
        rewards_growth_inside: vector<u128>
    ): u128 acquires PositionNft {
        abort 0
    }

    /// Update `PositionNFT` fee, return the fee_owned.
    /// Params
    ///     - position_id: Object<PositionNFT>
    ///     - fee_growth_inside_a: latest position fee growth_inside a
    ///     - fee_growth_inside_b: latest position fee growth_inside b
    public fun update_fee(
        pool_signer: &signer,
        position: Object<PositionNft>,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128
    ): (u64, u64) acquires PositionNft {
        abort 0
    }

    /// Update `PositionNFT` rewards, return the amount_owned vector.
    /// Params
    ///     - position_id: position nft id
    ///     - rewards_growth_inside: vector of latest position rewards growth_inside
    public fun update_rewards(
        pool_signer: &signer,
        position: Object<PositionNft>,
        rewards_growth_inside: vector<u128>,
    ): vector<u64> acquires PositionNft {
        abort 0
    }

    /// Update `PositionNFT` fee, reset the fee_owned_a and fee_owned_b and return the amount_owned.
    /// Params
    ///     - position_id: position nft id
    ///     - fee_growth_inside_a: latest position fee_growth_inside_a
    ///     - fee_growth_inside_b: latest position fee_growth_inside_b
    public fun update_and_reset_fee(
        pool_signer: &signer,
        position: Object<PositionNft>,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128
    ): (u64, u64) acquires PositionNft {
        abort 0
    }

    /// Update `PositionNFT` rewards
    /// Reset the amount_owned to 0
    /// Return the amount_owned
    public fun update_and_reset_rewards(
        pool_signer: &signer,
        position: Object<PositionNft>,
        rewards_growth_inside: vector<u128>,
    ): vector<u64> acquires PositionNft {
        abort 0
    }

    /// Reset the fee's amount owned to 0 and return the fee amount owned.
    public fun reset_fee(
        pool_signer: &signer,
        position: Object<PositionNft>,
    ): (u64, u64) acquires PositionNft {
        abort 0
    }

    /// Reset the rewarder's amount owned to 0 and return the reward num owned.
    public fun reset_rewarder(
        pool_signer: &signer,
        position: Object<PositionNft>,
    ): vector<u64> acquires PositionNft {
        abort 0
    }

    #[view]
    /// the inited reward count in `PositionNFT`.
    public fun inited_rewards_count(
        position: Object<PositionNft>,
    ): u64 acquires PositionNft {
        abort 0
    }

    #[view]
    /// Returns the amount of rewards owned by the position.
    public fun rewards_amount_owned(position: Object<PositionNft>): vector<u64> acquires PositionNft {
        abort 0
    }

    #[view]
    public fun pool_address(position: Object<PositionNft>): address {
        abort 0
    }

    #[view]
    public fun position_metadata(position: Object<PositionNft>): PositionMetadata acquires PositionNft {
        abort 0
    }

    public fun position_tick_range(metadata: &PositionMetadata): (I32, I32) {
        abort 0
    }

    public fun position_liquidity(metadata: &PositionMetadata): u128 {
        abort 0
    }

    public fun position_fee_growth_inside(metadata: &PositionMetadata): (u128, u128) {
        abort 0
    }

    public fun position_fee_owned(metadata: &PositionMetadata): (u64, u64) {
        abort 0
    }

    public fun position_rewards(position: Object<PositionNft>): vector<PositionReward> acquires PositionNft {
        abort 0
    }

    /// Check if a position tick range is valid.
    /// 1. lower < upper
    /// 2. (lower >= min_tick) && (upper <= max_tick)
    /// 3. (lower % tick_spacing == 0) && (upper % tick_spacing == 0)
    public fun check_position_tick_range(lower: I32, upper: I32, tick_spacing: u32) {
        abort 0
    }

    public fun is_position_empty(position: Object<PositionNft>): bool acquires PositionNft {
        abort 0
    }
}

