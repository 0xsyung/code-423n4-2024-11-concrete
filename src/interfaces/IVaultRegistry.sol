//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

interface IVaultRegistry {
    function addVault(address vault_, bytes32 vaultId_) external;
    function removeVault(address vault_, bytes32 vaultId_) external;
    function getAllVaults() external view returns (address[] memory);
    function getVaultsByImplementationId(bytes32 id_) external view returns (address[] memory);
    function getVaultsByToken(address asset) external view returns (address[] memory);
    function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external;
    function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external;
}
