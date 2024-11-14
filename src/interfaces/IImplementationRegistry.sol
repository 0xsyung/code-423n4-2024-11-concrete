//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

struct ImplementationData {
    address implementationAddress;
    bool initDataRequired;
}

interface IImplementationRegistry {
    function addImplementation(bytes32 id_, ImplementationData calldata implementation_) external;
    function getImplementation(bytes32 id_) external view returns (ImplementationData memory);
    function removeImplementation(bytes32 id_) external;
}
