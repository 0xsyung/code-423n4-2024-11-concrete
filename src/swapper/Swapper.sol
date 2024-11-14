// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

// Openzeppelin Libraries
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Openzeppelin Interface, Extensions and Contracts
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Blueprint Custom Errors, Constants and Data Types
import {Errors} from "../interfaces/Errors.sol";
import {BASISPOINTS} from "../interfaces/Constants.sol";
import {SwapperRewards} from "../interfaces/DataTypes.sol";

// Blueprint Interfaces
import {IRewardManager} from "../interfaces/IRewardManager.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";

// Blueprint Inheritable Contracts
import {OraclePlug} from "./OraclePlug.sol";

contract SwapperEvents {
    // Swapped event
    event Swapped(
        address indexed user,
        address ctAssetToken,
        address rewardToken,
        uint256 ctAssetAmount,
        uint256 reward
    );
    // Treasury change request events
    event TreasuryUpdated(address treasury);
    // Reward manager update event
    event RewardManagerUpdated(address rewardManager);
}

/// @title Swapper contract
/// @notice This contract is responsible for swapping ctAsset tokens for reward tokens
/// @dev The contract is Ownable and uses the OraclePlug contract
/// @author Blueprint Finance
contract Swapper is OraclePlug, Ownable, SwapperEvents, ReentrancyGuard, ISwapper {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address internal immutable _treasury;
    IRewardManager internal _rewardManager;
    // by default all reward tokens are available for withdrawal
    mapping(address => bool) internal _unavailableForWithdrawal;

    /// @notice Constructor for the Swapper contract
    /// @param owner_ The address of the owner of the contract
    /// @param tokenRegistry_ The address of the TokenRegistry contract
    /// @param rewardManager_ The address of the RewardManager contract
    /// @param treasury_ The address of the Treasury contract
    /// @dev The constructor sets the owner, the tokenRegistry, the rewardManager and the treasury
    constructor(
        address owner_,
        address tokenRegistry_,
        address rewardManager_,
        address treasury_
    ) Ownable(owner_) OraclePlug(tokenRegistry_) {
        if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();
        _treasury = treasury_;
        _rewardManager = IRewardManager(rewardManager_);
    }

    // External functions ////////////////////////////////////////

    /// @notice Swaps ctAsset tokens for reward tokens
    /// @param ctAssetToken_ The address of the ctAsset token
    /// @param rewardToken_ The address of the reward token
    /// @param ctAssetAmount_ The amount of ctAsset tokens to swap
    /// @dev The function checks if the reward token is a valid reward token
    function swapTokensForReward(
        address ctAssetToken_,
        address rewardToken_,
        uint256 ctAssetAmount_
    ) external nonReentrant {
        if (!_tokenRegistry.isRewardToken(rewardToken_)) revert Errors.NotValidRewardToken(rewardToken_);

        uint256 rewardAmount = _quoteSwapFromCtAssetToReward(ctAssetToken_, rewardToken_, ctAssetAmount_);

        if (!amountAvailableForWithdrawal(rewardToken_, rewardAmount)) {
            revert Errors.NotAvailableForWithdrawal(rewardToken_, rewardAmount);
        }

        // first send the ctAsset tokens to the treasury
        IERC20(ctAssetToken_).safeTransferFrom(msg.sender, address(_treasury), ctAssetAmount_);
        // this isn't an issue because the msg,sender first need to pay with the ctAsset token
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(rewardToken_).safeTransferFrom(address(_treasury), msg.sender, rewardAmount);

        emit Swapped(msg.sender, ctAssetToken_, rewardToken_, ctAssetAmount_, rewardAmount);
    }

    // Setter functions ////////////////////////////////////////

    /// @notice Sets the reward manager address
    /// @param rewardManager_ The address of the rewards manager
    /// @dev The function can only be called by the owner
    function setRewardManager(address rewardManager_) external onlyOwner {
        _rewardManager = IRewardManager(rewardManager_);
        emit RewardManagerUpdated(rewardManager_);
    }

    /// @notice Disables the swap of a token
    /// @param token_ The address of the token
    /// @param disableSwap_ A boolean indicating if the token is available for swap
    function disableTokenForSwap(address token_, bool disableSwap_) external onlyOwner {
        _unavailableForWithdrawal[token_] = disableSwap_;
    }

    // View functions ////////////////////////////////////////

    /// @notice Previews the swap of ctAsset tokens for reward tokens
    /// @param ctAssetToken_ The address of the ctAsset token
    /// @param rewardToken_ The address of the reward token
    /// @param ctAssetAmount_ The amount of ctAsset tokens to swap
    /// @return rewardAmount The amount of reward tokens
    /// @return availableForWithdrawal A boolean indicating if the reward token is available for withdrawal
    /// @return isRewardToken A boolean indicating if the reward token is a valid reward token
    /// @dev The function checks if the token is registered and whether its a valid reward token
    function previewSwapTokensForReward(
        address ctAssetToken_,
        address rewardToken_,
        uint256 ctAssetAmount_
    ) public view returns (uint256 rewardAmount, bool availableForWithdrawal, bool isRewardToken) {
        // If token is not registered, one cannot use the oracle to get the price
        if (!_tokenRegistry.isRegistered(rewardToken_)) return (0, false, false);

        // Check if the token is actually a reward token, i.e. can be withdrawn from the treasury
        isRewardToken = _tokenRegistry.isRewardToken(rewardToken_);

        // Check if the treasury allows for the withdrawal of the reward token
        availableForWithdrawal = amountAvailableForWithdrawal(rewardToken_, rewardAmount);

        // get the quote from the oracle
        rewardAmount = _quoteSwapFromCtAssetToReward(ctAssetToken_, rewardToken_, ctAssetAmount_);
    }

    /// @notice Checks if the reward token is available for withdrawal
    /// @param rewardToken_ The address of the reward token
    /// @return A boolean indicating if the reward token is available for withdrawal
    /// @dev The function checks if the reward token is available for withdrawal
    function tokenAvailableForWithdrawal(address rewardToken_) public view returns (bool) {
        return !_unavailableForWithdrawal[rewardToken_];
    }

    /// @notice Checks if the amount is available for withdrawal
    /// @param rewardToken_ The address of the reward token
    /// @param rewardAmount The amount of reward tokens
    /// @return A boolean indicating if the amount is available for withdrawal
    /// @dev The function checks if the amount is available for withdrawal
    function amountAvailableForWithdrawal(address rewardToken_, uint256 rewardAmount) public view returns (bool) {
        if (_unavailableForWithdrawal[rewardToken_]) {
            return false;
        }
        return IERC20(rewardToken_).balanceOf(_treasury) >= rewardAmount;
    }

    // Getter functions ////////////////////////////////////////

    /// @notice Gets the address of the reward manager
    /// @return The address of the reward manager
    function getRewardManager() public view returns (address) {
        return address(_rewardManager);
    }

    /// @notice Gets the address of the treasury
    /// @return The address of the treasury
    function getTreasury() public view returns (address) {
        return address(_treasury);
    }

    // Internal functions ////////////////////////////////////////

    /// @notice Quotes the swap of ctAsset tokens for reward tokens
    /// @param ctAssetToken_ The address of the ctAsset token
    /// @param rewardToken_ The address of the reward token
    /// @param ctAssetAmount_ The amount of ctAsset tokens to swap
    /// @return The amount of reward tokens
    /// @dev The function computes the reward rate and the reward amount
    function _quoteSwapFromCtAssetToReward(
        address ctAssetToken_,
        address rewardToken_,
        uint256 ctAssetAmount_
    ) internal view returns (uint256) {
        // get amount in stables
        uint256 ctAssetAmountInStables = _convertFromCtAssetTokenToStable(ctAssetToken_, ctAssetAmount_);

        // compute the reward rate using the quoteSwapperRewardrate function on the reward Manager
        uint256 rewardRate = _rewardManager.quoteSwapperRewardrate(
            msg.sender,
            ctAssetToken_,
            rewardToken_,
            ctAssetAmountInStables
        );

        // compute the reward amount in Stables
        uint256 rewardStableAmount = rewardRate == 0
            ? 0
            : ctAssetAmountInStables.mulDiv(rewardRate, BASISPOINTS, Math.Rounding.Floor);

        // convert the reward amount in stables to the amount in reward token
        return _convertFromStableToToken(rewardToken_, ctAssetAmountInStables + rewardStableAmount);
    }
}
