//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {ImplementationData} from "./IImplementationRegistry.sol";

interface IVaultDeploymentManager {
    function addImplementation(bytes32 id_, ImplementationData calldata implementation_) external;
    function removeImplementation(bytes32 id_) external;
    function deployNewVault(bytes32 id_, bytes calldata data_) external returns (address);
    function removeVault(address vault_, bytes32 vaultId_) external;
    function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external;
    function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external;
}
