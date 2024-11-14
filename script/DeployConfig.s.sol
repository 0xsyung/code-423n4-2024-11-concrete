//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract DeployConfig is Script {
    string public _json;

    constructor(string memory path_) {
        console.log("DeployConfig: Reading file %s", path_);
        try vm.readFile(path_) returns (string memory data) {
            _json = data;
        } catch {
            console.log("DeployConfig: Failed to read file %s: %s", path_);
        }
    }
}
