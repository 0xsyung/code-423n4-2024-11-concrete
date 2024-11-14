//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Chains} from "./Chains.sol";

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

abstract contract Deployer is Script {
    uint256 internal chainId;

    function setUp() public virtual {
        chainId = vm.envOr("CHAIN_ID", block.chainid);
    }

    function _getDeploymentContext() internal view returns (string memory) {
        string memory context = vm.envOr("DEPLOYMENT_CONTEXT", string(""));
        if (bytes(context).length > 0) {
            return context;
        }

        uint256 chainid = vm.envOr("CHAIN_ID", block.chainid);
        if (chainid == Chains.Mainnet) {
            return "mainnet";
        } else if (chainid == Chains.ArbVTN) {
            return "arb-vtn";
        } else {
            return vm.toString(chainid);
        }
    }

    function _save(string memory _name, address _deployed, string memory outputPath_) internal {
        vm.writeJson({json: stdJson.serialize("", _name, _deployed), path: outputPath_});
    }
}
