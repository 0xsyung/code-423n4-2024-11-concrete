// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";
import {Errors} from "../interfaces/Errors.sol";
import {IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";

/// @title Implementation Registry
/// @notice Manages the registration and removal of contract implementations.
/// @dev Inherits from Ownable for access control and utilizes Errors for custom error handling.
contract ImplementationRegistry is Ownable, Errors, IImplementationRegistry {
    /// @notice Mapping of implementation ID to its data.
    /// @dev The ID is a bytes32 hash derived from encoding the name and version of the implementation.
    mapping(bytes32 => ImplementationData) private _implementations;

    /// @notice Mapping to track if an implementation ID exists.
    mapping(bytes32 => bool) public implementationExists;

    /// @notice Array to keep track of all implementation addresses added.
    address[] public allImplementations;

    /// @notice Event emitted when a new implementation is added.
    event ImplementationAdded(bytes32 indexed id, ImplementationData implementation);

    event ImplementationRemoved(bytes32 indexed id, ImplementationData implementation);

    /// @param owner_ The address of the contract owner.
    constructor(address owner_) Ownable(owner_) {}

    /// @notice Adds a new implementation to the registry.
    /// @param id_ The unique identifier for the implementation.
    /// @param implementation_ The implementation data including the address and whether initialization data is required.
    /// @dev Emits an ImplementationAdded event upon success.
    function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {
        if (implementationExists[id_]) {
            revert ImplementationAlreadyExists(id_);
        }

        _implementations[id_] = implementation_;
        implementationExists[id_] = true;
        allImplementations.push(implementation_.implementationAddress);

        emit ImplementationAdded(id_, implementation_);
    }

    /// @notice Removes an implementation from the registry.
    /// @param id_ The unique identifier for the implementation to remove.
    /// @dev Sets the implementation data to a default value and removes it from the tracking array.
    function removeImplementation(bytes32 id_) external onlyOwner {
        if (!implementationExists[id_]) {
            revert ImplementationDoesNotExist(id_);
        }
        address impAddress = _implementations[id_].implementationAddress;
        emit ImplementationRemoved(id_, _implementations[id_]);
        delete _implementations[id_];
        implementationExists[id_] = false;

        uint256 indexToBeRemoved = 0;
        uint256 len = allImplementations.length;
        for (uint256 i = 0; i < len; ) {
            if (allImplementations[i] == impAddress) {
                indexToBeRemoved = i;
                break;
            }
            unchecked {
                i++;
            }
        }

        allImplementations[indexToBeRemoved] = allImplementations[len - 1];
        allImplementations.pop();
    }

    /// @notice Retrieves the implementation data for a given ID.
    /// @param id_ The unique identifier for the implementation.
    /// @return The implementation data.
    function getImplementation(bytes32 id_) external view returns (ImplementationData memory) {
        return _implementations[id_];
    }

    /// @notice Retrieves all historical implementation addresses.
    /// @return An array of all implementation addresses ever added.
    function getHistoricalImplementationAddresses() external view returns (address[] memory) {
        return allImplementations;
    }
}
