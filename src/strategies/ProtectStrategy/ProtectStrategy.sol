//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC20, IERC20Metadata, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {StrategyBase, RewardToken} from "../StrategyBase.sol";
import {IProtectStrategy} from "../../interfaces/IProtectStrategy.sol";
import {IConcreteMultiStrategyVault} from "../../interfaces/IConcreteMultiStrategyVault.sol";

contract ProtectStrategyEvents {
    event BorrowDebtRepayed(uint256 prevAmount, uint256 substractedAmount);
    event BorrowClaimExecuted(uint256 amount, address recipient);
    event ClaimRouterAddressUpdated(address claimRouter);
}

//! Owner will need to be an admin control contract
/// @title ProtectStrategy
/// @author gerantonyk
/// @notice ProtectStrategy is a special strategy to interact with the borrow flow
contract ProtectStrategy is StrategyBase, IProtectStrategy, ProtectStrategyEvents {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 private borrowDebt = 0;
    address public claimRouter;

    constructor(IERC20 baseAsset_, address feeRecipient_, address owner_, address claimRouter_, address vault_) {
        IERC20Metadata metaERC20 = IERC20Metadata(address(baseAsset_));

        //This can be initially set to zero and then updated by the owner
        //slither-disable-next-line missing-zero-check
        claimRouter = claimRouter_;

        RewardToken[] memory rewardTokenEmptyArray = new RewardToken[](0);
        __StrategyBase_init(
            baseAsset_,
            string.concat("Concrete Earn Protect ", metaERC20.symbol(), " Strategy"),
            string.concat("ctPct-", metaERC20.symbol()),
            feeRecipient_,
            type(uint256).max,
            owner_,
            rewardTokenEmptyArray,
            vault_
        );
        //slither-disable-next-line unused-return
        //baseAsset_.approve(claimRouter, type(uint256).max);
    }

    modifier onlyClaimRouter() {
        if (claimRouter != _msgSender()) {
            revert ClaimRouterUnauthorizedAccount(_msgSender());
        }
        _;
    }

    /**
     * @notice Returns whether this contract is a protect strategy.
     * @dev This function returns true as this contract represents a protect strategy.
     * @return true
     */
    function isProtectStrategy() external pure returns (bool) {
        return true;
    }

    function highWatermark() external view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 totalAssets_ = totalAssets();
        if (totalSupply_ == 0) return 1;
        return totalAssets_.mulDiv(10 ** uint256(DECIMAL_OFFSET), totalSupply_, Math.Rounding.Ceil);
    }

    // function harvestRewards(bytes memory) public virtual override(IStrategy, StrategyBase) returns (ReturnedRewards[] memory) {
    //     return new ReturnedRewards[](0);
    // }

    /**
     * @notice Returns the available assets for withdrawal.
     * @dev This function retrieves the balance of the underlying asset held by this contract.
     * @return The total available assets for withdrawal.
     */
    function getAvailableAssetsForWithdrawal() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /// @notice Function to set the address of the claim router contract.
    /// @dev Sets the claim router address to the specified value.
    /// @param claimRouter_ The new address of the claim router contract.
    function setClaimRouter(address claimRouter_) external onlyOwner {
        if (claimRouter_ == address(0)) revert InvalidClaimRouterAddress();
        claimRouter = claimRouter_;
        emit ClaimRouterAddressUpdated(claimRouter_);
    }
    /**
     * @dev Returns the total assets under management in this strategy (it doesn't include the balance).
     * @return The total amount of assets in the strategy without the balanceOf.
     */

    function _totalAssets() internal view override returns (uint256) {
        return borrowDebt;
    }

    /**
     * @notice Returns the current borrow debt.
     * @dev This function retrieves the current borrow debt of the protect strategy.
     * @return The current borrow debt.
     */
    function getBorrowDebt() external view returns (uint256) {
        return borrowDebt;
    }

    /**
     * @notice Substracts from the borrow debt.
     * @dev This function updates the borrow debt of the protect strategy.
     * @param amount The amount to subtract from the borrow debt.
     */
    function updateBorrowDebt(uint256 amount) external override onlyClaimRouter {
        if (borrowDebt < amount) revert InvalidSubstraction();
        emit BorrowDebtRepayed(borrowDebt, amount);
        borrowDebt -= amount;
    }

    /**
     * @notice Executes a borrow claim.
     * @dev This function transfers the specified amount of assets to the recipient and updates the borrow debt.
     * @param amount The amount to transfer to the recipient.
     * @param recipient The address of the recipient.
     */
    //this function is only callable by the claim router wich we controll, no reentrancy possible
    //slither-disable-next-line reentrancy-benign,reentrancy-events
    function executeBorrowClaim(uint256 amount, address recipient) external override onlyClaimRouter {
        if (amount == 0) revert ZeroAmount();
        uint256 balance = getAvailableAssetsForWithdrawal();

        if (balance < amount) {
            _requestFromVault(amount - balance);
        }

        borrowDebt += amount;

        IERC20(asset()).safeTransfer(recipient, amount);

        emit BorrowClaimExecuted(amount, recipient);
    }

    /**
     * @dev Requests assets from the vault.
     * @param amount_ The amount of assets to request from the vault.
     */
    function _requestFromVault(uint256 amount_) private {
        IConcreteMultiStrategyVault(_vault).requestFunds(amount_);
    }

    function _handleRewardsOnWithdraw() internal override {}
    function _getRewardsToStrategy(bytes memory) internal override {}
    function getRewardTokenAddresses() public view override returns (address[] memory _rewardTokens) {}
}
