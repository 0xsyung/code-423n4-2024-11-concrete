//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";

interface IVaultFactory {
    function deployVault(
        ImplementationData calldata implementationData,
        bytes calldata data_,
        bytes32 salt_
    ) external returns (address);
}
