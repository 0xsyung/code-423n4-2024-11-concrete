//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IConcreteMultiStrategyVault, VaultFees, Strategy, Allocation} from "../interfaces/IConcreteMultiStrategyVault.sol";
import {ImplementationData, IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import {IVaultDeploymentManager} from "../interfaces/IVaultDeploymentManager.sol";
import {WithdrawalQueue} from "../queue/WithdrawalQueue.sol";

contract VaultManager is AccessControl {
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    IVaultRegistry public vaultRegistry;
    IVaultDeploymentManager public deploymentManager;

    event AllVaultsPaused();
    event AllVaultsUnpaused();

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_MANAGER_ROLE, admin);
    }

    function adminSetup(
        IVaultRegistry vaultRegistry_,
        IVaultDeploymentManager deploymentManager_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vaultRegistry = vaultRegistry_;
        deploymentManager = deploymentManager_;
    }

    //============================================
    // -------- Master Vault Functions -----------
    //============================================

    // Pausing and Unpausing
    function pauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).pause();
    }

    function unpauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).unpause();
    }

    function pauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {
        address[] memory vaults = vaultRegistry.getAllVaults();
        emit AllVaultsPaused();
        uint256 vaultsLength = vaults.length;
        for (uint256 i = 0; i < vaultsLength; ) {
            //We control both the length of the array and the external call
            // slither-disable-next-line calls-loop
            IConcreteMultiStrategyVault(vaults[i]).pause();
            unchecked {
                i++;
            }
        }
    }

    function unpauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {
        emit AllVaultsUnpaused();
        address[] memory vaults = vaultRegistry.getAllVaults();
        uint256 vaultsLength = vaults.length;
        for (uint256 i = 0; i < vaultsLength; ) {
            //We control both the length of the array and the external call
            // slither-disable-next-line calls-loop
            IConcreteMultiStrategyVault(vaults[i]).unpause();
            unchecked {
                i++;
            }
        }
    }

    function deployNewVault(
        bytes32 id_,
        bytes calldata data_
    ) external onlyRole(VAULT_MANAGER_ROLE) returns (address newVaultAddress) {
        newVaultAddress = deploymentManager.deployNewVault(id_, data_);
        WithdrawalQueue queue = new WithdrawalQueue(newVaultAddress);
        IConcreteMultiStrategyVault(newVaultAddress).setWithdrawalQueue(address(queue));
    }

    function registerNewImplementation(
        bytes32 id_,
        ImplementationData memory implementation_
    ) external onlyRole(VAULT_MANAGER_ROLE) {
        deploymentManager.addImplementation(id_, implementation_);
    }

    function removeImplementation(bytes32 id_) external onlyRole(VAULT_MANAGER_ROLE) {
        deploymentManager.removeImplementation(id_);
    }

    function removeVault(address vault_, bytes32 vaultId_) external onlyRole(VAULT_MANAGER_ROLE) {
        deploymentManager.removeVault(vault_, vaultId_);
    }

    function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).setVaultFees(fees_);
    }

    function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).setFeeRecipient(newRecipient_);
    }

    function toggleIdleVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).toggleVaultIdle();
    }

    function addReplaceStrategy(
        address vault_,
        uint256 index_,
        bool replace_,
        Strategy calldata newStrategy_
    ) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).addStrategy(index_, replace_, newStrategy_);
    }

    function removeStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).removeStrategy(index_);
    }

    //TODO test this function
    function changeStrategyAllocations(
        address vault_,
        Allocation[] calldata newAllocations_,
        bool redistribute_
    ) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).changeAllocations(newAllocations_, redistribute_);
    }

    function pushFundsToStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).pushFundsToStrategies();
    }

    function pushFundsToSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).pushFundsIntoSingleStrategy(index_);
    }

    function pushFundsToSingleStrategy(
        address vault_,
        uint256 index_,
        uint256 amount
    ) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).pushFundsIntoSingleStrategy(index_, amount);
    }

    function pullFundsFromSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).pullFundsFromSingleStrategy(index_);
    }

    function pullFundsFromStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).pullFundsFromStrategies();
    }

    function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).setDepositLimit(limit_);
    }

    function batchClaimWithdrawal(address vault_, uint256 maxRequests) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).batchClaimWithdrawal(maxRequests);
    }

    function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {
        IConcreteMultiStrategyVault(vault_).setWithdrawalQueue(withdrawalQueue_);
    }

    //============================================
    // ----------- Strategy Functions ------------
    //============================================
}
