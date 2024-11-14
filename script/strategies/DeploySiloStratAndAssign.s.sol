//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployBaseStratAndAssign} from "./DeployBaseStratAndAssign.s.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20, IERC20Metadata, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SiloV1Strategy} from "../../src/strategies/Silo/SiloV1Strategy.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";

contract DeploySiloStratAndAssign is DeployBaseStratAndAssign {
    address siloAsset;
    address siloRepository;
    address siloIncentivesController;
    address[] extraRewardAssets;
    uint256[] extraRewardFees;

    function setUp() public virtual override {
        stratType = "Silo";
        super.setUp();
    }

    function _deployStrat() internal override returns (IStrategy) {
        strategy = new SiloV1Strategy(
            IERC20Metadata(IERC4626(vault).asset()),
            feeRecipient,
            deployer,
            rewardFee,
            siloAsset,
            siloRepository,
            siloIncentivesController,
            extraRewardAssets,
            extraRewardFees,
            vault
        );
        return strategy;
    }

    function _getStratData() internal override {
        super._getStratData();

        // get the variables from the cfgStratJson
        bytes memory siloAssetBytes = vm.parseJson(cfgStratJson, ".siloAsset");
        siloAsset = abi.decode(siloAssetBytes, (address));
        bytes memory siloRepositoryBytes = vm.parseJson(cfgStratJson, ".siloRepository");
        siloRepository = abi.decode(siloRepositoryBytes, (address));
        bytes memory siloIncentivesControllerBytes = vm.parseJson(cfgStratJson, ".siloIncentivesController");
        siloIncentivesController = abi.decode(siloIncentivesControllerBytes, (address));
        bytes memory extraRewardAssetsBytes = vm.parseJson(cfgStratJson, ".extraRewardAssets");
        extraRewardAssets = abi.decode(extraRewardAssetsBytes, (address[]));
        bytes memory extraRewardFeesBytes = vm.parseJson(cfgStratJson, ".extraRewardFees");
        extraRewardFees = abi.decode(extraRewardFeesBytes, (uint256[]));
    }
}
