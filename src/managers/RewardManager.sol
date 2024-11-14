//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SwapperRewards} from "../interfaces/DataTypes.sol";
import {BASISPOINTS} from "../interfaces/Constants.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "../interfaces/Errors.sol";

/// @title Reward Manager contract
/// @notice This contract is responsible for managing the reward rates for the swapper
/// @dev The contract is Ownable
/// @author Blueprint Finance
contract RewardManagerEvents {
    event SwapperRewardsUpdated(
        uint16 baseRewardrate,
        uint16 maxProgressionFactor,
        uint256 progressionUpperBound,
        uint16 bonusRewardrateUser,
        uint16 bonusRewardrateCtToken,
        uint16 bonusRewardrateSwapToken
    );
    event SwapperBaseRewardrateUpdated(uint16 baseRewardrate);
    event SwapperMaxProgressionFactorUpdated(uint16 maxProgressionFactor);
    event SwapperProgressionUpperBoundUpdated(uint256 progressionUpperBound);
    event SwapperBonusRewardrateForUserUpdated(uint16 bonusRewardrateUser);
    event SwapperBonusRewardrateForCtTokenUpdated(uint16 bonusRewardrateCtToken);
    event SwapperBonusRewardrateForSwapTokenUpdated(uint16 bonusRewardrateSwapToken);
    event SwapperBonusRateForRewardTokenEnabled(address rewardToken, bool enableBonusRate);
    event SwapperBonusRateForCtTokenEnabled(address ctAssetToken, bool enableBonusRate);
}

contract RewardManager is RewardManagerEvents, Ownable {
    using Math for uint256;

    SwapperRewards internal _swapperRewards;
    mapping(address => bool) internal _swapperGetsBonusRate;
    mapping(address => bool) internal _swappedRewardTokenGetsBonusRate;
    mapping(address => bool) internal _swappedCtTokenGetsBonusRate;

    /// @notice Constructor for the RewardManager contract
    /// @param owner_ The address of the owner of the contract
    /// @param baseRewardrate_ The base reward rate
    /// @param maxProgressionFactor_ The maximum progression factor
    /// @param progressionUpperBound_ The progression upper bound
    /// @param bonusRewardrateUser_ The bonus reward rate for the user
    /// @param bonusRewardrateCtToken_ The bonus reward rate for the ctToken
    /// @param bonusRewardrateSwapToken_ The bonus reward rate for the swap token
    /// @dev The constructor sets the owner and the swapper rewards
    constructor(
        address owner_,
        uint16 baseRewardrate_,
        uint16 maxProgressionFactor_,
        uint256 progressionUpperBound_,
        uint16 bonusRewardrateUser_,
        uint16 bonusRewardrateCtToken_,
        uint16 bonusRewardrateSwapToken_
    ) Ownable(owner_) {
        if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();
        if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();
        if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();
        if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();
        if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

        _swapperRewards = SwapperRewards({
            baseRewardrate: baseRewardrate_,
            maxProgressionFactor: maxProgressionFactor_,
            progressionUpperBound: SafeCast.toUint176(progressionUpperBound_),
            bonusRewardrateUser: bonusRewardrateUser_,
            bonusRewardrateCtToken: bonusRewardrateCtToken_,
            bonusRewardrateSwapToken: bonusRewardrateSwapToken_
        });
    }

    /// @notice Set the base reward rate
    /// @param baseRewardrate_ The base reward rate in basis points
    /// @dev The function reverts if the base reward rate is greater than 100%
    function setSwapperBaseRewardrate(uint16 baseRewardrate_) external onlyOwner {
        if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();
        _swapperRewards.baseRewardrate = baseRewardrate_;
        emit SwapperBaseRewardrateUpdated(baseRewardrate_);
    }

    /// @notice Set the maximum progression factor
    /// @param maxProgressionFactor_ The maximum progression factor in basis points
    /// @dev The function reverts if the maximum progression factor is greater than 100%. The progression factor is the maximum rate to which the reward rate can progress depending on the deposited amount. If it exceeds the progression upper bound, it will be capped at the maximum progression factor.
    function setSwapperMaxProgressionFactor(uint16 maxProgressionFactor_) external onlyOwner {
        if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();
        _swapperRewards.maxProgressionFactor = maxProgressionFactor_;
        emit SwapperMaxProgressionFactorUpdated(maxProgressionFactor_);
    }

    /// @notice Set the progression upper bound
    /// @param progressionUpperBound_ The progression upper bound
    /// @dev The progression upper bound is the maximum amount of ctAsset tokens that can be deposited to reach the maximum progression factor. More can be deposited, but then the reward percentage wont increase any further.
    function setSwapperProgressionUpperBound(uint256 progressionUpperBound_) external onlyOwner {
        _swapperRewards.progressionUpperBound = SafeCast.toUint176(progressionUpperBound_);
        emit SwapperProgressionUpperBoundUpdated(progressionUpperBound_);
    }

    /// @notice Set the bonus reward rate for the user
    /// @param bonusRewardrateForUser_ The bonus reward rate for the user
    /// @dev The function reverts if the bonus reward rate for the user is greater than 100%
    function setSwapperBonusRewardrateForUser(uint16 bonusRewardrateForUser_) external onlyOwner {
        if (bonusRewardrateForUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();
        _swapperRewards.bonusRewardrateUser = bonusRewardrateForUser_;
        emit SwapperBonusRewardrateForUserUpdated(bonusRewardrateForUser_);
    }

    /// @notice Set the bonus reward rate for the ctToken
    /// @param bonusRewardrateForCtToken_ The bonus reward rate for the ctAssetToken
    /// @dev The function reverts if the bonus reward rate for the ctToken is greater than 100%
    function setSwapperBonusRewardrateForCtToken(uint16 bonusRewardrateForCtToken_) external onlyOwner {
        if (bonusRewardrateForCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();
        _swapperRewards.bonusRewardrateCtToken = bonusRewardrateForCtToken_;
        emit SwapperBonusRewardrateForCtTokenUpdated(bonusRewardrateForCtToken_);
    }

    /// @notice Set the bonus reward rate for the swap token
    /// @param bonusRewardrateForSwapToken_ The bonus reward rate for the swap token
    /// @dev The function reverts if the bonus reward rate for the swap token is greater than 100%
    function setSwapperBonusRewardrateForSwapToken(uint16 bonusRewardrateForSwapToken_) external onlyOwner {
        if (bonusRewardrateForSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();
        _swapperRewards.bonusRewardrateSwapToken = bonusRewardrateForSwapToken_;
        emit SwapperBonusRewardrateForSwapTokenUpdated(bonusRewardrateForSwapToken_);
    }

    /// @notice Sets all the rates and bounds for the swapper rewards
    /// @param baseRewardrate_ The base reward rate in basis points
    /// @param maxProgressionFactor_ The maximum progression factor in basis points
    /// @param progressionUpperBound_ The progression upper bound
    /// @param bonusRewardrateUser_ The bonus reward rate for the user in basis points
    /// @param bonusRewardrateCtToken_ The bonus reward rate for the ctToken in basis points
    /// @param bonusRewardrateSwapToken_ The bonus reward rate for the swap token in basis points
    /// @dev The function reverts if any of the rates are greater than 100%
    function setSwapperRewards(
        uint16 baseRewardrate_,
        uint16 maxProgressionFactor_,
        uint256 progressionUpperBound_,
        uint16 bonusRewardrateUser_,
        uint16 bonusRewardrateCtToken_,
        uint16 bonusRewardrateSwapToken_
    ) external onlyOwner {
        if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();
        if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();
        if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();
        if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();
        if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

        _swapperRewards = SwapperRewards({
            baseRewardrate: baseRewardrate_,
            maxProgressionFactor: maxProgressionFactor_,
            progressionUpperBound: SafeCast.toUint176(progressionUpperBound_),
            bonusRewardrateUser: bonusRewardrateUser_,
            bonusRewardrateCtToken: bonusRewardrateCtToken_,
            bonusRewardrateSwapToken: bonusRewardrateSwapToken_
        });
        emit SwapperRewardsUpdated(
            baseRewardrate_,
            maxProgressionFactor_,
            progressionUpperBound_,
            bonusRewardrateUser_,
            bonusRewardrateCtToken_,
            bonusRewardrateSwapToken_
        );
    }

    /// @notice Enable or disable the bonus reward rate for a user
    /// @param user_ The address of the user
    /// @param enableBonusRate_ The boolean to enable or disable the bonus rate
    /// @dev The function reverts if the user address is the zero address or if the caller is not the owner.
    function enableSwapperBonusRateForUser(address user_, bool enableBonusRate_) external onlyOwner {
        if (user_ == address(0)) revert Errors.InvalidUserAddress();
        _swapperGetsBonusRate[user_] = enableBonusRate_;
    }

    /// @notice Enable or disable the bonus reward rate for a reward token
    /// @param rewardToken_ The address of the reward token
    /// @param enableBonusRate_ The boolean to enable or disable the bonus rate
    /// @dev The function reverts if the caller is not the owner.
    function enableSwapperBonusRateForRewardToken(address rewardToken_, bool enableBonusRate_) external onlyOwner {
        _swappedRewardTokenGetsBonusRate[rewardToken_] = enableBonusRate_;
        emit SwapperBonusRateForRewardTokenEnabled(rewardToken_, enableBonusRate_);
    }

    /// @notice Enable or disable the bonus reward rate for a ctAsset Token
    /// @param ctAssetToken_ The address of the ctAsset token
    /// @param enableBonusRate_ The boolean to enable or disable the bonus rate
    /// @dev The function reverts if the caller is not the owner.
    function enableSwapperBonusRateForCtToken(address ctAssetToken_, bool enableBonusRate_) external onlyOwner {
        _swappedCtTokenGetsBonusRate[ctAssetToken_] = enableBonusRate_;
        emit SwapperBonusRateForCtTokenEnabled(ctAssetToken_, enableBonusRate_);
    }

    // Getter functions ////////////////////////////////////////

    /// @notice Get the base reward rate
    /// @return baseRewardrate The base reward rate
    function getSwapperBaseRewardrate() external view returns (uint256) {
        return uint256(_swapperRewards.baseRewardrate);
    }

    /// @notice Get the maximum progression factor
    /// @return maxProgressionFactor The maximum progression factor
    function getMaxProgressionFactor() external view returns (uint256) {
        return uint256(_swapperRewards.maxProgressionFactor);
    }

    /// @notice Get the progression upper bound
    /// @return progressionUpperBound The progression upper bound
    function getSwapperProgressionUpperBound() external view returns (uint256) {
        return uint256(_swapperRewards.progressionUpperBound);
    }

    /// @notice Get the bonus reward rate for the user
    /// @return bonusRewardrateUser The bonus reward rate for the user
    function getSwapperBonusRewardrateForUser() external view returns (uint256) {
        return uint256(_swapperRewards.bonusRewardrateUser);
    }

    /// @notice Get the bonus reward rate for the ctToken
    /// @return bonusRewardrateCtToken The bonus reward rate for the ctToken
    function getSwapperBonusRewardrateForCtToken() external view returns (uint256) {
        return uint256(_swapperRewards.bonusRewardrateCtToken);
    }

    /// @notice Get the bonus reward rate for the swap token
    /// @return bonusRewardrateSwapToken The bonus reward rate for the swap token
    function getSwapperBonusRewardrateForSwapToken() external view returns (uint256) {
        return uint256(_swapperRewards.bonusRewardrateSwapToken);
    }

    /// @notice Get a quote for the reward rate.
    /// @param user_ The address of the user
    /// @param ctAssetToken_ The address of the ctAsset token
    /// @param rewardToken_ The address of the reward token
    /// @param ctAssetAmountInStables_ The amount of ctAsset tokens in stables
    /// @return rewardRate The reward rate
    /// @dev The function computes the reward rate for the user that wants to swap a ctAsset token for a reward token
    function quoteSwapperRewardrate(
        address user_,
        address ctAssetToken_,
        address rewardToken_,
        uint256 ctAssetAmountInStables_
    ) external view returns (uint256 rewardRate) {
        // Set base reward rate
        rewardRate = uint256(_swapperRewards.baseRewardrate);
        // Handle bonus reward rate

        if (_swapperGetsBonusRate[user_]) {
            rewardRate += uint256(_swapperRewards.bonusRewardrateUser);
        }

        if (_swappedCtTokenGetsBonusRate[ctAssetToken_]) {
            rewardRate += uint256(_swapperRewards.bonusRewardrateCtToken);
        }

        if (_swappedRewardTokenGetsBonusRate[rewardToken_]) {
            rewardRate += uint256(_swapperRewards.bonusRewardrateSwapToken);
        }

        // Handle progression factor
        if (_swapperRewards.maxProgressionFactor != 0) {
            uint256 progressionFactor;
            if (ctAssetAmountInStables_ > _swapperRewards.progressionUpperBound) {
                progressionFactor = uint256(_swapperRewards.maxProgressionFactor);
            } else {
                progressionFactor = ctAssetAmountInStables_.mulDiv(
                    uint256(_swapperRewards.maxProgressionFactor),
                    uint256(_swapperRewards.progressionUpperBound),
                    Math.Rounding.Floor
                );
            }

            rewardRate += progressionFactor;
        }
    }

    /// @notice Get a boolean flag, indicating whether the user gets a bonus rate.
    /// @param user_ The address of the user
    /// @return rewardRate The boolean flag
    /// @dev The function reverts if the caller is neither the owner nor the user.
    function swapperBonusRateForUser(address user_) external view returns (bool) {
        if (!(owner() == _msgSender() || user_ == _msgSender())) revert Errors.InvalidUserAddress();
        return _swapperGetsBonusRate[user_];
    }

    /// @notice Get a boolean flag, indicating whether the reward token gets a bonus rate.
    /// @param rewardToken_ The address of the reward token
    /// @return rewardRate The boolean flag
    function swapperBonusRateForRewardToken(address rewardToken_) external view returns (bool) {
        return _swappedRewardTokenGetsBonusRate[rewardToken_];
    }

    /// @notice Get a boolean flag, indicating whether the ctAsset token gets a bonus rate.
    /// @param ctAssetToken_ The address of the ctAsset token
    /// @return rewardRate The boolean flag
    function swapperBonusRateForCtToken(address ctAssetToken_) external view returns (bool) {
        return _swappedCtTokenGetsBonusRate[ctAssetToken_];
    }
}
