//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

pragma solidity ^0.8.20;

import {DeployBaseStratAndAssign} from "./DeployBaseStratAndAssign.s.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {ProtectStrategy} from "../../src/strategies/ProtectStrategy/ProtectStrategy.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";

contract DeployProtectStratAndAssign is DeployBaseStratAndAssign {
    address claimRouterAddress;

    function setUp() public virtual override {
        stratType = "Protect";
        super.setUp();
    }

    function _deployStrat() internal override returns (IStrategy) {
        strategy = new ProtectStrategy(
            IERC20(IERC4626(vault).asset()),
            feeRecipient,
            deployer,
            claimRouterAddress,
            vault
        );
        return strategy;
    }

    function _getAddressesData() internal override {
        super._getAddressesData();

        bytes memory claimRouterAddressBytes = vm.parseJson(cfgJson, ".ClaimRouter");
        claimRouterAddress = abi.decode(claimRouterAddressBytes, (address));
    }
}
