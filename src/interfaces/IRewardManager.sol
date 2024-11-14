//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/// @title IRewardManager
/// @notice This interface defines the functions for the RewardManager contract.
interface IRewardManager {
    /// @notice Retrieves the reward rate for a swapper.
    /// @param user_ The address of the user.
    /// @param ctAssetToken_ The address of the ctAsset token.
    /// @param rewardToken_ The address of the reward token.
    /// @param ctAssetAmountInStables_ The amount of ctAsset in stables.
    /// @return The reward rate for the swapper.
    function quoteSwapperRewardrate(
        address user_,
        address ctAssetToken_,
        address rewardToken_,
        uint256 ctAssetAmountInStables_
    ) external view returns (uint16);

    /// @notice Retrieves the base reward rate for a swapper.
    /// @return The base reward rate for the swapper.
    function getSwapperBaseRewardrate() external view returns (uint16);

    /// @notice Retrieves the maximum progression factor for a swapper.
    /// @return The maximum progression factor for the swapper.
    function getMaxProgressionFactor() external view returns (uint16);

    /// @notice Retrieves the progression upper bound for a swapper.
    /// @return The progression upper bound for the swapper.
    function getSwapperProgressionUpperBound() external view returns (uint256);

    /// @notice Retrieves the bonus reward rate for a swapper.
    /// @return The bonus reward rate for the swapper.
    function getSwapperBonusRewardrate() external view returns (uint16);

    /// @notice Sets the bonus rate for a user.
    /// @param user_ The address of the user.
    function setSwapperBonusRateUser(address user_, bool getsBonusRate_) external;
}
