// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Errors} from "../interfaces/Errors.sol";
import {IClaimRouter, VaultFlags} from "../interfaces/IClaimRouter.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import {IProtectStrategy} from "../interfaces/IProtectStrategy.sol";
import {IConcreteMultiStrategyVault} from "../interfaces/IConcreteMultiStrategyVault.sol";
import {OraclePlug} from "../swapper/OraclePlug.sol";
import {IProtectStrategy} from "../interfaces/IProtectStrategy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @title Claim Router Events
/// @notice This contract contains all events used in the Claim Router contract.
/// @author gerantonyk

contract ClaimRouterEvents {
    event TokenCascadeUpdated();
    event BlueprintRoleGranted(address blueprint);
    event VaultRegistryUpdated(address vaultRegistry);
    event ClaimRequested(address indexed protectionStrat, uint256 amount, address asset, address userBlueprint);
    event Repayment(address indexed protectionStrat, uint256 amount);
    event RewardAdded(address indexed protectionStrat, uint256 amount);
    event DustCleaned(address indexed protectionStrat, uint256 amount);
}
//! Owner will need to be an admin control contract
/// @title ClaimRouter
/// @author gerantonyk
/// @notice ClaimRouter is a contract that allows the protocol to interact with
/// multiple protect strategies routing the claim requests to the best one available.

contract ClaimRouter is AccessControl, Errors, IClaimRouter, OraclePlug, ClaimRouterEvents {
    using Math for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant BLUEPRINT_ROLE = keccak256("BLUEPRINT_ROLE");

    /// @notice Address of the vault registry contract.

    struct DebtVaults {
        uint256 totalBorrowDebt;
        uint256 vaultsWithProtect;
    }

    IVaultRegistry public vaultRegistry;

    /// @notice List of tokens to iterate over in case we cant fulfil a request in the requested token.
    address[] public tokenCascade;

    /// @notice Constructor function to initialize the contract.
    /// @dev Initializes the contract with the specified parameters.
    /// @param owner The address of the owner of the contract.
    /// @param vaultRegistry_ The address of the vault registry contract.
    /// @param tokenRegistry_ The address of the token registry contract.
    /// @param blueprint_ The address of the blueprint contract.
    /// @param tokenCascade_ An array containing addresses representing the token cascade.
    constructor(
        address owner,
        address vaultRegistry_,
        address tokenRegistry_,
        address[] memory blueprint_,
        address[] memory tokenCascade_
    ) OraclePlug(tokenRegistry_) {
        if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();
        if (owner == address(0)) revert InvalidDefaultAdminAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, owner);

        uint256 len = blueprint_.length;
        for (uint256 i = 0; i < len; ) {
            if (blueprint_[i] != address(0)) _grantRole(BLUEPRINT_ROLE, blueprint_[i]);
            unchecked {
                i++;
            }
        }
        vaultRegistry = IVaultRegistry(vaultRegistry_);
        _setTokenCascade(tokenCascade_);
    }

    /// @notice Function to set the address of the vault registry contract.
    /// @dev Sets the vault registry address to the specified value.
    /// @param vaultRegistry_ The new address of the vault registry contract.
    function setVaultRegistry(address vaultRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();
        vaultRegistry = IVaultRegistry(vaultRegistry_);
        emit VaultRegistryUpdated(vaultRegistry_);
    }

    /// @notice Function to set the token cascade for the vault.
    /// @dev Sets the token cascade to the specified array of addresses.
    /// @param tokenCascade_ The new token cascade to be set.
    function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete tokenCascade;
        _setTokenCascade(tokenCascade_);
        emit TokenCascadeUpdated();
    }

    /// @notice Internal function to set the token cascade for the vault.
    /// @dev Sets the token cascade to the specified array of addresses structs.
    /// @param tokenCascade_ The new token cascade to be set.
    function _setTokenCascade(address[] memory tokenCascade_) internal {
        uint256 len = tokenCascade_.length;
        for (uint256 i; i < len; ) {
            //We control both the length of the array and the external call
            // slither-disable-next-line calls-loop
            if (tokenCascade_[i] == address(0x0)) {
                revert InvalidAssetAddress();
            }
            tokenCascade.push(tokenCascade_[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Internal function to get the protection strategy for withdrawing assets.
    /// @dev Retrieves the protection strategy for withdrawing assets from the vault.
    /// @param tokenAddress The address of the token.
    /// @param amount The amount of assets to withdraw.
    /// @return The address of the selected protection strategy and a boolean indicating if additional funds are required.
    //we control the external call
    //slither-disable-next-line calls-loop
    function _getStrategy(address tokenAddress, uint256 amount) internal view returns (address, bool) {
        //retrieves all vaults created for an specific token

        address[] memory vaults = vaultRegistry.getVaultsByToken(tokenAddress);
        //TODO change to a criteria where when can decidede base on yield

        address selectedProtectionStrat = address(0x0);
        bool requiresFunds = true;
        //Iterates over array of vaults to find the best vault to withdraw from
        uint256 len = vaults.length;
        uint256 maxYieldFound = type(uint256).max;
        for (uint256 i; i < len; ) {
            IConcreteMultiStrategyVault currentVault = IConcreteMultiStrategyVault(vaults[i]);

            address protectionStrat = currentVault.protectStrategy();

            //only considers vaults with protection strategies
            if (protectionStrat == address(0x0)) {
                unchecked {
                    i++;
                }
                continue;
            }

            uint256 protectionStratYield = IProtectStrategy(protectionStrat).highWatermark();

            //if the protection strategy has enough assets to withdraw we are done with the search
            if (
                IProtectStrategy(protectionStrat).getAvailableAssetsForWithdrawal() >= amount &&
                (protectionStratYield < maxYieldFound || requiresFunds)
            ) {
                selectedProtectionStrat = protectionStrat;
                requiresFunds = false;
                maxYieldFound = protectionStratYield;
            }

            if (!requiresFunds) {
                unchecked {
                    i++;
                }
                continue;
            }

            if (currentVault.getAvailableAssetsForWithdrawal() >= amount && protectionStratYield < maxYieldFound) {
                selectedProtectionStrat = protectionStrat;
                requiresFunds = true;
                maxYieldFound = protectionStratYield;
            }
            unchecked {
                i++;
            }
        }
        return (selectedProtectionStrat, requiresFunds);
    }

    /// @notice Function to request assets from the vault.
    /// @dev Requests assets from the vault and executes a borrow claim through the protection strategy.
    /// @param tokenAddress The address of the token.
    /// @param amount_ The amount of assets to request.
    /// @param userBlueprint The address of the user's blueprint contract.
    function requestToken(
        VaultFlags,
        address tokenAddress,
        uint256 amount_,
        address payable userBlueprint
    ) external onlyRole(BLUEPRINT_ROLE) {
        uint256 amount = amount_;
        (address protectionStrat, bool requiresFunds) = _getStrategy(tokenAddress, amount);
        if (protectionStrat == address(0x0)) {
            //iterates over array
            uint256 len = tokenCascade.length;
            for (uint256 i; i < len; ) {
                //We avoid using the same token as the one that failed
                if (tokenAddress == tokenCascade[i]) {
                    unchecked {
                        i++;
                    }
                    continue;
                }
                //TODO change amount

                amount = _convertFromTokenToStable(tokenAddress, amount_);

                //We control both the length of the array and the external call
                // slither-disable-next-line calls-loop
                (protectionStrat, requiresFunds) = _getStrategy(tokenCascade[i], amount);
                if (protectionStrat != address(0x0)) {
                    break;
                }
                unchecked {
                    i++;
                }
            }
        }

        if (protectionStrat == address(0x0)) {
            revert NoProtectionStrategiesFound();
        }
        emit ClaimRequested(protectionStrat, amount, IProtectStrategy(protectionStrat).asset(), userBlueprint);
        IProtectStrategy(protectionStrat).executeBorrowClaim(amount, userBlueprint);
    }

    /// @notice Function to add rewards to the protection strategy.
    /// @dev Adds rewards to the protection strategy associated with the token address.
    /// @param tokenAddress The address of the token.
    /// @param amount_ The amount of rewards to add.
    /// @param userBlueprint The address of the user's blueprint contract.
    function addRewards(
        address tokenAddress,
        uint256 amount_,
        address userBlueprint
    ) external onlyRole(BLUEPRINT_ROLE) {
        _addTokensToStrategy(tokenAddress, amount_, userBlueprint, true);
    }

    /// @notice Function to repay borrowed assets.
    /// @dev Repays borrowed assets to the protection strategy associated with the token address.
    /// @param tokenAddress The address of the token.
    /// @param amount_ The amount of assets to repay.
    /// @param userBlueprint The address of the user's blueprint contract.
    function repay(address tokenAddress, uint256 amount_, address userBlueprint) external onlyRole(BLUEPRINT_ROLE) {
        _addTokensToStrategy(tokenAddress, amount_, userBlueprint, false);
    }

    /// @notice Function to add tokens to the protection strategy.
    /// @dev Adds tokens to the protection strategy associated with the token address.
    /// @param tokenAddress The address of the token.
    /// @param amount_ The amount of tokens to add.
    /// @param userBlueprint The address of the user's blueprint contract.
    /// @param isReward Boolean indicating whether the tokens are added as a reward.
    //This is a private function and every public function that calls it requires the blueprint role
    //slither-disable-next-line reentrancy-events
    function _addTokensToStrategy(address tokenAddress, uint256 amount_, address userBlueprint, bool isReward) private {
        if (amount_ == 0) revert ZeroAmount();
        //If we add one more variable we get a stack too deep error
        DebtVaults memory debtVaults = _getTokenTotalBorrowDebt(tokenAddress);

        //if totalBorrowDebt is zero we distribute evenly the amount to all the protection strategies
        if (debtVaults.vaultsWithProtect == 0) revert NoProtectionStrategiesFound();

        address[] memory vaults = vaultRegistry.getVaultsByToken(tokenAddress);

        uint256 totalSent = 0;

        address lastProtectionStrat = address(0x0);
        // uint256 len = vaults.length;

        for (uint256 i; i < vaults.length; ) {
            address protectionStrat = IConcreteMultiStrategyVault(vaults[i]).protectStrategy();

            //only considers vaults with protection strategies
            if (protectionStrat == address(0x0)) {
                unchecked {
                    i++;
                }
                continue;
            }

            lastProtectionStrat = protectionStrat;
            uint256 stratBorrowDebt = IProtectStrategy(protectionStrat).getBorrowDebt();

            uint256 amountToBeSent = 0;
            if (debtVaults.totalBorrowDebt != 0) {
                if (stratBorrowDebt == 0) {
                    unchecked {
                        i++;
                    }
                    continue;
                }
                amountToBeSent = amount_.mulDiv(stratBorrowDebt, debtVaults.totalBorrowDebt, Math.Rounding.Floor);
            } else {
                //slither-disable-next-line unused-return
                (, amountToBeSent) = amount_.tryDiv(debtVaults.vaultsWithProtect);
            }

            //this function is only called by the blueprint so we can trust the userBlueprint
            totalSent += amountToBeSent;
            //TODO HAndle cases where the amount sent is more the one expected
            //the funtion should be able to set the rest as rewards in the case of the reapyment exceding the debt

            //slither-disable-next-line arbitrary-send-erc20
            IERC20(tokenAddress).safeTransferFrom(userBlueprint, protectionStrat, amountToBeSent);
            if (isReward || stratBorrowDebt == 0) {
                emit RewardAdded(protectionStrat, amountToBeSent);
                unchecked {
                    i++;
                }
                continue;
            }

            if (amountToBeSent > stratBorrowDebt) {
                emit RewardAdded(protectionStrat, amountToBeSent - stratBorrowDebt);

                emit Repayment(protectionStrat, stratBorrowDebt);
                IProtectStrategy(protectionStrat).updateBorrowDebt(stratBorrowDebt);
            } else {
                emit Repayment(protectionStrat, amountToBeSent);
                IProtectStrategy(protectionStrat).updateBorrowDebt(amountToBeSent);
            }
            unchecked {
                i++;
            }
        }
        if (amount_ > totalSent) {
            emit DustCleaned(lastProtectionStrat, amount_ - totalSent);
            //slither-disable-next-line arbitrary-send-erc20
            IERC20(tokenAddress).safeTransferFrom(userBlueprint, lastProtectionStrat, amount_ - totalSent);
        }
    }

    /// @notice Function to calculate the total borrow debt for a specific token across all vaults.
    /// @dev Calculates the total borrow debt by summing the borrow debts from all vaults associated with the token.
    /// @param tokenAddress The address of the token.
    /// @return data The total borrow debt for the token.
    function _getTokenTotalBorrowDebt(address tokenAddress) private view returns (DebtVaults memory data) {
        address[] memory vaults = vaultRegistry.getVaultsByToken(tokenAddress);
        data.vaultsWithProtect = 0;
        uint256 len = vaults.length;
        data.totalBorrowDebt = 0;
        for (uint256 i; i < len; ) {
            IConcreteMultiStrategyVault currentVault = IConcreteMultiStrategyVault(vaults[i]);
            address protectionStrat = currentVault.protectStrategy();
            if (protectionStrat != address(0x0)) {
                data.vaultsWithProtect++;
                data.totalBorrowDebt += IProtectStrategy(protectionStrat).getBorrowDebt();
            }
            unchecked {
                i++;
            }
        }
        return data;
    }

    /// @notice Function to calculate the total avaliable tokens for protection across all vaults.
    /// @dev Calculates the total avaliable amount for protection from all vaults associated with the token.
    /// @param tokenAddress The address of the token.
    /// @return total The total avaliable tokens for protection.
    //we control the external call
    //slither-disable-next-line calls-loop
    function getTokenTotalAvaliableForProtection(address tokenAddress) external view returns (uint256 total) {
        address[] memory vaults = vaultRegistry.getVaultsByToken(tokenAddress);
        uint256 len = vaults.length;
        total = 0;
        for (uint256 i; i < len; ) {
            IConcreteMultiStrategyVault currentVault = IConcreteMultiStrategyVault(vaults[i]);
            address protectionStrat = currentVault.protectStrategy();
            if (protectionStrat != address(0x0)) {
                total += currentVault.getAvailableAssetsForWithdrawal();
            }
            unchecked {
                i++;
            }
        }
    }
}
