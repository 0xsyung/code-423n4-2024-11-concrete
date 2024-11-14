// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

// Importing necessary contracts and interfaces from OpenZeppelin and local files
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VaultFactory} from "../factories/VaultFactory.sol";
import {ImplementationData, IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import {IVaultDeploymentManager} from "../interfaces/IVaultDeploymentManager.sol";
import {Errors} from "../interfaces/Errors.sol";

/// @title Deployment Manager for Vault Contracts
/// @notice Manages the deployment and registration of new vaults, and the addition or removal of their implementations.
/// @dev Inherits from Ownable for access control and implements IVaultDeploymentManager for deployment management.
contract DeploymentManager is Ownable, Errors, IVaultDeploymentManager {
    // State variables for the contract addresses of the vault factory, implementation registry, and vault registry
    IVaultFactory immutable vaultFactory;
    IImplementationRegistry immutable implementationRegistry;
    IVaultRegistry immutable vaultRegistry;

    /// @notice Constructor to set initial contract addresses for the vault factory, implementation registry, and vault registry.
    /// @param owner_ The address of the contract owner.
    /// @param vaultFactory_ The address of the VaultFactory contract.
    /// @param implementationRegistry_ The address of the ImplementationRegistry contract.
    /// @param vaultRegistry_ The address of the VaultRegistry contract.
    constructor(
        address owner_,
        address vaultFactory_,
        address implementationRegistry_,
        address vaultRegistry_
    ) Ownable(owner_) {
        vaultFactory = IVaultFactory(vaultFactory_);
        implementationRegistry = IImplementationRegistry(implementationRegistry_);
        vaultRegistry = IVaultRegistry(vaultRegistry_);
    }

    /// @notice Adds a new implementation to the registry.
    /// @param id_ The unique identifier for the implementation.
    /// @param implementation_ The implementation data including the address and whether initialization data is required.
    /// @dev Only callable by the contract owner.
    function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {
        implementationRegistry.addImplementation(id_, implementation_);
    }

    /// @notice Removes an implementation from the registry.
    /// @param id_ The unique identifier for the implementation to remove.
    /// @dev Only callable by the contract owner.
    function removeImplementation(bytes32 id_) external onlyOwner {
        implementationRegistry.removeImplementation(id_);
    }

    /// @notice Deploys a new vault using a specified implementation.
    /// @param id_ The unique identifier for the implementation to use for the new vault.
    /// @param data_ The initialization data to be passed to the new vault.
    /// @dev Only callable by the contract owner.
    /// @dev Reverts if the specified implementation does not exist.
    function deployNewVault(bytes32 id_, bytes calldata data_) external onlyOwner returns (address newVaultAddress) {
        // Retrieve the implementation data from the registry
        ImplementationData memory implementationData = implementationRegistry.getImplementation(id_);
        // Revert if the implementation address is invalid
        if (implementationData.implementationAddress == address(0)) {
            revert InvalidImplementation(id_);
        }
        uint256 vaultCount = vaultRegistry.getAllVaults().length;
        bytes32 salt = keccak256(
            abi.encode(address(this), implementationData.implementationAddress, vaultCount, block.timestamp)
        );
        // Deploy the new vault using the vault factory and register it in the vault registry
        newVaultAddress = vaultFactory.deployVault(implementationData, data_, salt);
        vaultRegistry.addVault(newVaultAddress, id_);
        //TODO
    }

    function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {
        vaultRegistry.removeVault(vault_, vaultId_);
    }

    /// @notice Sets the limit for the number of vaults per token.
    /// @dev If there is already a token with more vaults than the new limit, it will be impossible
    /// to add new vaults for that token. Additionally, tokens with the limit exceeded could still exist.
    /// @param vaultByTokenLimit_ The new limit for the number of vaults per token.
    function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {
        vaultRegistry.setVaultByTokenLimit(vaultByTokenLimit_);
    }

    /// @notice Sets the total number of vaults allowed.
    /// @param totalVaultsAllowed_ The new limit for the total number of vaults.
    function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {
        vaultRegistry.setTotalVaultsAllowed(totalVaultsAllowed_);
    }
}
