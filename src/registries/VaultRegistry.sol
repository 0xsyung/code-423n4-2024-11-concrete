// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import {Errors} from "../interfaces/Errors.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
/// @title Vault Registry
/// @notice Manages the registration and tracking of vaults.
/// @dev Inherits from Ownable for access control and utilizes Errors for custom error handling.

contract VaultRegistry is IVaultRegistry, Ownable, Errors {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public vaultByTokenLimit = 100;

    uint256 public totalVaultsAllowed = 1000;

    /// @notice Tracks if a vault exists.
    mapping(address => bool) public vaultExists;

    /// @notice Maps a vault ID to an array of vault addresses.
    mapping(bytes32 => address[]) public vaultIdToAddressArray;

    /// @notice Array of all vaults created.
    address[] public allVaultsCreated;

    /// @notice Maps asset to vault addresses.
    mapping(address => EnumerableSet.AddressSet) private vaultsByToken;

    /// @notice Emitted when a vault is added.
    /// @param vault The address of the vault added.
    /// @param vaultId The ID of the vault.

    event VaultAdded(address indexed vault, bytes32 indexed vaultId);

    /// @param owner_ The address of the contract owner.
    constructor(address owner_) Ownable(owner_) {}

    /// @notice Adds a new vault to the registry.
    /// @param vault_ The address of the vault to add.
    /// @param vaultId_ The ID of the vault.
    /// @dev Reverts if the vault already exists.
    /// @dev Emits a VaultAdded event upon success.
    function addVault(address vault_, bytes32 vaultId_) external override onlyOwner {
        if (vault_ == address(0)) revert VaultZeroAddress();

        if (vaultExists[vault_]) {
            revert VaultAlreadyExists();
        }
        vaultExists[vault_] = true;
        vaultIdToAddressArray[vaultId_].push(vault_);
        allVaultsCreated.push(vault_);

        if (allVaultsCreated.length > totalVaultsAllowed) revert TotalVaultsAllowedExceeded(allVaultsCreated.length);

        address underlyingAsset = IERC4626(vault_).asset();

        assert(vaultsByToken[underlyingAsset].add(vault_));

        if (vaultsByToken[underlyingAsset].length() > vaultByTokenLimit) {
            revert VaultByTokenLimitExceeded(underlyingAsset, vaultsByToken[underlyingAsset].length());
        }
        emit VaultAdded(vault_, vaultId_);
    }

    function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {
        vaultExists[vault_] = false;
        _handleRemoveVault(vault_, allVaultsCreated);
        _handleRemoveVault(vault_, vaultIdToAddressArray[vaultId_]);
        assert(vaultsByToken[IERC4626(vault_).asset()].remove(vault_));
    }

    /// @notice Retrieves all vaults created.
    /// @return An array of addresses of all vaults created.
    function getAllVaults() external view returns (address[] memory) {
        return allVaultsCreated;
    }

    /// @notice Retrieves vaults by their implementation ID.
    /// @param id_ The implementation ID of the vaults to retrieve.
    /// @return An array of addresses of vaults with the specified implementation ID.
    function getVaultsByImplementationId(bytes32 id_) external view returns (address[] memory) {
        return vaultIdToAddressArray[id_];
    }

    function getVaultsByToken(address asset) external view virtual returns (address[] memory vaults) {
        return vaultsByToken[asset].values();
    }

    function _handleRemoveVault(address vault_, address[] storage vaultArray_) internal {
        uint256 length = vaultArray_.length;
        uint256 i = 0;
        for (i = 0; i < length; ) {
            if (vaultArray_[i] == vault_) {
                if (i < length - 1) {
                    vaultArray_[i] = vaultArray_[length - 1];
                }
                vaultArray_.pop();
                break;
            }
            unchecked {
                i++;
            }
        }
        if (i == length) {
            revert VaultDoesNotExist(vault_);
        }
    }

    /// @notice Sets the limit for the number of vaults per token.
    /// @dev If there is already a token with more vaults than the new limit, it will be impossible
    /// to add new vaults for that token. Additionally, tokens with the limit exceeded could still exist.
    /// @param vaultByTokenLimit_ The new limit for the number of vaults per token.
    function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {
        vaultByTokenLimit = vaultByTokenLimit_;
    }

    /// @notice Sets the total number of vaults allowed.
    /// @param totalVaultsAllowed_ The new limit for the total number of vaults.
    function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {
        if (totalVaultsAllowed_ < allVaultsCreated.length) revert TotalVaultsAllowedExceeded(allVaultsCreated.length);
        totalVaultsAllowed = totalVaultsAllowed_;
    }
}
