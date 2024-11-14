//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MAX_BASIS_POINTS} from "../utils/Constants.sol";
import {VaultFees, Strategy} from "../interfaces/IConcreteMultiStrategyVault.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

library MultiStrategyVaultHelper {
    using Math for uint256;
    using SafeERC20 for IERC20;

    error InvalidVaultFees();
    error InvalidAssetAddress();
    error InvalidFeeRecipient();
    error VaultAssetMismatch();
    error ERC20ApproveFail();
    error InvalidIndex(uint256 index);
    error AllotmentTotalTooHigh();
    error MultipleProtectStrat();
    error StrategyHasLockedAssets(address strategy);

    /// @notice Initializes, validates, and approves the base asset for each strategy.
    /// @param strategies_ The array of strategies to be initialized.
    /// @param baseAsset_ The base asset (IERC20 token) for approval.
    /// @param protectStrategy_ The address of the current protect strategy, if any.
    /// @param strategies The storage array where validated strategies will be stored.
    /// @return address The updated protect strategy address.
    function initializeStrategies(
        Strategy[] memory strategies_,
        IERC20 baseAsset_,
        address protectStrategy_,
        Strategy[] storage strategies
    ) private returns (address) {
        uint256 len = strategies_.length;

        for (uint256 i = 0; i < len; ) {
            IStrategy currentStrategy = strategies_[i].strategy;

            // Validate that the strategy asset matches the base asset
            if (currentStrategy.asset() != address(baseAsset_)) {
                revert VaultAssetMismatch();
            }

            // Check if the strategy is a protect strategy and ensure only one is allowed
            if (currentStrategy.isProtectStrategy()) {
                if (protectStrategy_ != address(0)) revert MultipleProtectStrat();
                protectStrategy_ = address(currentStrategy);
            }

            // Add the validated strategy to the storage array
            strategies.push(strategies_[i]);

            // Approve the base asset for the strategy
            baseAsset_.forceApprove(address(currentStrategy), type(uint256).max);

            // Use unchecked increment to avoid gas cost for overflow checks (safe since len is controlled)
            unchecked {
                i++;
            }
        }

        return protectStrategy_;
    }

    /// @notice Validates and assigns fee values from `fees_` to `fees`.
    /// @param fees_ The input VaultFees structure containing fee values to validate and assign.
    /// @param fees The storage VaultFees structure where validated fees will be stored.
    function validateAndSetFees(VaultFees memory fees_, VaultFees storage fees) private {
        // Validate basic fee values to ensure they don't exceed MAX_BASIS_POINTS
        if (
            fees_.depositFee >= MAX_BASIS_POINTS ||
            fees_.withdrawalFee >= MAX_BASIS_POINTS ||
            fees_.protocolFee >= MAX_BASIS_POINTS
        ) {
            revert InvalidVaultFees();
        }

        // Assign validated fee values
        fees.depositFee = fees_.depositFee;
        fees.withdrawalFee = fees_.withdrawalFee;
        fees.protocolFee = fees_.protocolFee;

        // Copy the performanceFee array to storage with a loop
        uint256 len = fees_.performanceFee.length;
        for (uint256 i = 0; i < len; ) {
            fees.performanceFee.push(fees_.performanceFee[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Validates and initializes essential vault parameters, including the base asset, strategies, and fee structure.
     * @dev Ensures the provided base asset address is valid, initializes strategies with allocations,
     *      adjusts decimals for the base asset, and validates and sets vault fees.
     *      Reverts if the base asset address is zero or if the fees or strategy allocations are invalid.
     * @param baseAsset_ The IERC20 token that serves as the base asset of the vault.
     * @param decimalOffset The offset to be added to the base asset's decimals to calculate vault decimals.
     * @param strategies_ The array of strategies with allocation data to be initialized for the vault.
     * @param protectStrategy_ The current protect strategy address, if any, to be used for specific operations.
     * @param strategies The storage array where validated and initialized strategies will be stored.
     * @param fees_ The memory VaultFees structure containing the initial fee values for the vault.
     * @param fees The storage VaultFees structure where validated fees will be stored and used by the vault.
     * @return protectStrategy The address of the protect strategy if set after initialization.
     * @return decimals The calculated number of decimals for the vault based on the base asset and decimal offset.
     * @custom:reverts InvalidAssetAddress if the base asset address is zero.
     * @custom:reverts AllotmentTotalTooHigh if the total strategy allocations exceed 100%.
     * @custom:reverts InvalidVaultFees if any fee value exceeds the maximum basis points allowed.
     */
    function validateVaultParameters(
        IERC20 baseAsset_,
        uint8 decimalOffset,
        Strategy[] memory strategies_,
        address protectStrategy_,
        Strategy[] storage strategies,
        VaultFees memory fees_,
        VaultFees storage fees
    ) public returns (address protectStrategy, uint8 decimals) {
        if (address(baseAsset_) == address(0)) {
            revert InvalidAssetAddress();
        }

        protectStrategy = initializeStrategies(strategies_, baseAsset_, protectStrategy_, strategies);

        decimals = IERC20Metadata(address(baseAsset_)).decimals() + decimalOffset;

        validateAndSetFees(fees_, fees);
    }

    /// @notice Calculates the tiered fee based on share value and high water mark.
    /// @param shareValue The current value of a share in assets.
    /// @param highWaterMark The high water mark for performance fee calculation.
    /// @param totalSupply The total supply of shares in the vault.
    /// @param fees The fee structure containing performance fee tiers.
    /// @return fee The calculated performance fee.
    /// @dev This function Must only be called when the share value strictly exceeds the high water mark.
    function calculateTieredFee(
        uint256 shareValue,
        uint256 highWaterMark,
        uint256 totalSupply,
        VaultFees storage fees
    ) public view returns (uint256 fee) {
        if (shareValue <= highWaterMark) return 0;
        // Calculate the percentage difference (diff) between share value and high water mark
        uint256 diff = uint256(shareValue.mulDiv(MAX_BASIS_POINTS, highWaterMark, Math.Rounding.Floor)) -
            uint256(MAX_BASIS_POINTS);

        // Loop through performance fee tiers
        uint256 len = fees.performanceFee.length;
        if (len == 0) return 0;
        for (uint256 i = 0; i < len; ) {
            if (diff < fees.performanceFee[i].upperBound && diff > fees.performanceFee[i].lowerBound) {
                fee = ((shareValue - highWaterMark) * totalSupply).mulDiv(
                    fees.performanceFee[i].fee,
                    MAX_BASIS_POINTS * 1e18,
                    Math.Rounding.Floor
                );
                break; // Exit loop once the correct tier is found
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Distributes assets to each strategy based on their allocation.
    /// @param strategies The array of strategies, each with a specified allocation.
    /// @param _totalAssets The total amount of assets to be distributed.
    function distributeAssetsToStrategies(Strategy[] storage strategies, uint256 _totalAssets) public {
        uint256 len = strategies.length;

        for (uint256 i = 0; i < len; ) {
            // Calculate the amount to allocate to each strategy based on its allocation percentage
            uint256 amountToDeposit = _totalAssets.mulDiv(
                strategies[i].allocation.amount,
                MAX_BASIS_POINTS,
                Math.Rounding.Floor
            );

            // Deposit the allocated amount into the strategy
            strategies[i].strategy.deposit(amountToDeposit, address(this));

            unchecked {
                i++;
            }
        }
    }

    /// @notice Adds or replaces a strategy, ensuring allotment limits and setting protect strategy if needed.
    /// @param strategies The storage array of current strategies.
    /// @param newStrategy_ The new strategy to add or replace.
    /// @param replace_ Boolean indicating if the strategy should replace an existing one.
    /// @param index_ The index at which to replace the strategy if `replace_` is true.
    /// @param protectStrategy The current protect strategy address, which may be updated.
    /// @param asset The asset of the vault for approving the strategy.
    /// @return protectStrategy The address of the new protect strategy.
    /// @return newStrategyIfc The interface of the new strategy.
    /// @return stratToBeReplacedIfc The interface of the strategy to be replaced. (could be empty if not replacing)
    function addOrReplaceStrategy(
        Strategy[] storage strategies,
        Strategy memory newStrategy_,
        bool replace_,
        uint256 index_,
        address protectStrategy_,
        IERC20 asset
    ) public returns (address protectStrategy, IStrategy newStrategyIfc, IStrategy stratToBeReplacedIfc) {
        // Calculate total allotments of current strategies
        protectStrategy = protectStrategy_;
        uint256 allotmentTotals = 0;
        uint256 len = strategies.length;
        for (uint256 i = 0; i < len; ) {
            allotmentTotals += strategies[i].allocation.amount;
            unchecked {
                i++;
            }
        }

        // Adding or replacing strategy based on `replace_` flag
        if (replace_) {
            if (index_ >= len) revert InvalidIndex(index_);

            // Ensure replacing doesn't exceed total allotment limit
            if (
                allotmentTotals - strategies[index_].allocation.amount + newStrategy_.allocation.amount >
                MAX_BASIS_POINTS
            ) {
                revert AllotmentTotalTooHigh();
            }

            // Replace the strategy at `index_`
            stratToBeReplacedIfc = strategies[index_].strategy;
            protectStrategy_ = removeStrategy(stratToBeReplacedIfc, protectStrategy_, asset);

            strategies[index_] = newStrategy_;
        } else {
            // Ensure adding new strategy doesn't exceed total allotment limit
            if (allotmentTotals + newStrategy_.allocation.amount > MAX_BASIS_POINTS) {
                revert AllotmentTotalTooHigh();
            }

            // Add the new strategy to the array
            strategies.push(newStrategy_);
        }

        // Handle protect strategy assignment if applicable
        if (newStrategy_.strategy.isProtectStrategy()) {
            if (protectStrategy_ != address(0)) revert MultipleProtectStrat();
            protectStrategy = address(newStrategy_.strategy);
        }

        // Approve the asset for the new strategy
        asset.forceApprove(address(newStrategy_.strategy), type(uint256).max);

        // Return the address of the new strategy
        newStrategyIfc = newStrategy_.strategy;
    }

    /// @notice Removes a strategy, redeeming assets if necessary, and resets protect strategy if applicable.
    /// @param stratToBeRemoved_ The strategy to be removed.
    /// @param protectStrategy_ The current protect strategy address, which may be updated.
    /// @param asset The asset of the vault for resetting the allowance to the strategy.
    /// @return protectStrategy The address of the removed strategy.
    function removeStrategy(
        IStrategy stratToBeRemoved_,
        address protectStrategy_,
        IERC20 asset
    ) public returns (address protectStrategy) {
        protectStrategy = protectStrategy_;
        // Check if the strategy has any locked assets that cannot be withdrawn
        if (stratToBeRemoved_.getAvailableAssetsForWithdrawal() != stratToBeRemoved_.totalAssets()) {
            revert StrategyHasLockedAssets(address(stratToBeRemoved_));
        }

        // Redeem all assets from the strategy if it has any assets
        if (stratToBeRemoved_.totalAssets() > 0) {
            stratToBeRemoved_.redeem(stratToBeRemoved_.balanceOf(address(this)), address(this), address(this));
        }

        // Reset protect strategy if the strategy being removed is the protect strategy
        if (protectStrategy_ == address(stratToBeRemoved_)) {
            protectStrategy = address(0);
        } else {
            protectStrategy = protectStrategy_;
        }

        // Reset allowance to zero for the strategy being removed
        asset.forceApprove(address(stratToBeRemoved_), 0);
    }

    function withdrawAssets(
        address asset, // The main asset token
        uint256 amount, // The requested withdrawal amount
        address protectStrategy, // The address of the strategy to skip
        Strategy[] storage strategies // Array of strategy structs
    ) public returns (uint256) {
        uint256 availableAssets = IERC20(asset).balanceOf(address(this));
        uint256 accumulated = availableAssets;

        // If available assets in main balance are insufficient, try strategies
        if (availableAssets < amount) {
            uint256 len = strategies.length;

            for (uint256 i = 0; i < len; i++) {
                IStrategy currentStrategy = strategies[i].strategy;

                // Skip the protect strategy
                if (address(currentStrategy) == protectStrategy) {
                    continue;
                }

                uint256 pending = amount - accumulated;

                // Check available assets in the strategy
                uint256 availableInStrategy = currentStrategy.getAvailableAssetsForWithdrawal();

                // Skip if the strategy has no assets available for withdrawal
                if (availableInStrategy == 0) {
                    continue;
                }

                // Determine the amount to withdraw from this strategy
                uint256 toWithdraw = availableInStrategy < pending ? availableInStrategy : pending;

                // Update the accumulated amount
                accumulated += toWithdraw;

                // Withdraw from the strategy
                currentStrategy.withdraw(toWithdraw, address(this), address(this));

                // Break if the accumulated amount satisfies the requested amount
                if (accumulated >= amount) {
                    break;
                }
            }
        }

        return accumulated;
    }
}
