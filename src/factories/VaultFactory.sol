// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ConcreteMultiStrategyVault} from "../vault/ConcreteMultiStrategyVault.sol";
import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";
import {Errors} from "../interfaces/Errors.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";

/// @title VaultFactory
/// @notice Factory contract for deploying vaults using the clone pattern for efficiency.
/// @dev Inherits from Ownable for access control and utilizes Errors for custom error handling.
contract VaultFactory is Ownable, Errors, IVaultFactory {
    /// @notice Emitted when a new vault is deployed.
    /// @param vaultAddress The address of the newly deployed vault.
    event VaultDeployed(address indexed vaultAddress);

    /// @dev Sets the contract owner upon deployment.
    /// @param owner The address of the contract owner.
    constructor(address owner) Ownable(owner) {}

    /// @notice Deploys a new vault using a specified implementation.
    /// @param implementation_ The implementation data including the address and whether initialization data is required.
    /// @param data_ The initialization data to be passed to the new vault, if required.
    /// @return newVault The address of the newly deployed vault.
    /// @dev Only callable by the contract owner.
    function deployVault(
        ImplementationData calldata implementation_,
        bytes calldata data_,
        bytes32 salt_
    ) external onlyOwner returns (address newVault) {
        // Deploy a new clone of the implementation.
        newVault = Clones.cloneDeterministic(implementation_.implementationAddress, salt_);

        emit VaultDeployed(newVault);

        // If initialization data is required, call the new vault with the provided data.
        if (implementation_.initDataRequired) {
            //Address can be 0x0
            // slither-disable-next-line missing-zero-check
            (bool success, ) = newVault.call(data_);
            // Revert if the initialization call fails.
            if (!success) {
                revert VaultDeployInitFailed();
            }
        }
        // Emit an event indicating the successful deployment of the vault.
    }
}
