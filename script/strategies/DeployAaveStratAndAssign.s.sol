//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployBaseStratAndAssign} from "./DeployBaseStratAndAssign.s.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {AaveV3Strategy} from "../../src/strategies/Aave/AaveV3Strategy.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";

contract DeployAaveStratAndAssign is DeployBaseStratAndAssign {
    address aaveDataProvider;

    function setUp() public virtual override {
        stratType = "Aave";
        super.setUp();
    }

    function _deployStrat() internal override returns (IStrategy) {
        strategy = new AaveV3Strategy(
            IERC20(IERC4626(vault).asset()),
            feeRecipient,
            deployer,
            rewardFee,
            aaveDataProvider,
            vault
        );

        return strategy;
    }

    function _getStratData() internal override {
        super._getStratData();

        bytes memory aaveDataProviderBytes = vm.parseJson(cfgStratJson, ".aaveDataProvider");
        aaveDataProvider = abi.decode(aaveDataProviderBytes, (address));
    }
}
