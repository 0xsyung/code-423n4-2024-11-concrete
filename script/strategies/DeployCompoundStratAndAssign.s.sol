//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

pragma solidity ^0.8.20;

import {DeployBaseStratAndAssign} from "./DeployBaseStratAndAssign.s.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {CompoundV3Strategy} from "../../src/strategies/compoundV3/CompoundV3Strategy.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";

contract DeployCompoundStratAndAssign is DeployBaseStratAndAssign {
    address cTokenAddress;
    address rewarderAddress;

    function setUp() public virtual override {
        stratType = "Compound";
        super.setUp();
    }

    function _deployStrat() internal override returns (IStrategy) {
        strategy = new CompoundV3Strategy(
            IERC20(IERC4626(vault).asset()),
            feeRecipient,
            deployer,
            rewardFee,
            rewarderAddress,
            cTokenAddress,
            vault
        );
        return strategy;
    }

    function _getStratData() internal override {
        super._getStratData();

        bytes memory cTokenAddressBytes = vm.parseJson(cfgStratJson, ".cTokenAddress");
        cTokenAddress = abi.decode(cTokenAddressBytes, (address));

        bytes memory rewarderAddressBytes = vm.parseJson(cfgStratJson, ".rewarderAddress");
        rewarderAddress = abi.decode(rewarderAddressBytes, (address));
    }
}
