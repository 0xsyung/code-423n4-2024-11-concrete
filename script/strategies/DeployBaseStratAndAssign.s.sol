//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Deployer} from "../Deployer.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {VaultManager} from "../../src/managers/VaultManager.sol";
import {DeployConfig} from "../DeployConfig.s.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";
import {Strategy, Allocation} from "../../src/interfaces/IConcreteMultiStrategyVault.sol";

abstract contract DeployBaseStratAndAssign is Deployer {
    address deployer;
    string outputPath;
    string deploymentContext;

    IStrategy public strategy;

    DeployConfig cfg;
    string cfgJson;
    DeployConfig cfgStrat;
    string cfgStratJson;

    uint256 allocationAmount;
    uint256 allocationIndex;
    address feeRecipient;
    uint256 rewardFee;
    uint256 indexInVault;
    bool replaceStrat;

    address vaultManagerAddress;
    address vault;

    string stratType;

    function setUp() public virtual override {
        deploymentContext = _getDeploymentContext();
        console.log("Deployment Context: %s", deploymentContext);
        string memory path = string.concat("./deploy-config/", deploymentContext, ".EarnCoreAddresses.json");
        cfg = new DeployConfig(path); // This can be used to read anything from config json
        cfgJson = cfg._json();

        string memory path2 = string.concat("./deploy-config/strategies/", deploymentContext, ".", stratType, ".json");
        cfgStrat = new DeployConfig(path2); // This can be used to read anything from config json
        cfgStratJson = cfgStrat._json();
    }

    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 vaultAddressUint = vm.envUint("VAULT_ADDRESS");
        vault = address(uint160(vaultAddressUint));
        outputPath = string.concat(
            "./deploy-config/strategies/",
            deploymentContext,
            ".",
            Strings.toHexString(uint160(vault), 20),
            ".",
            stratType,
            ".json"
        );
        vm.startBroadcast(deployerPrivateKey);
        _getAddressesData();
        _getStratData();
        deployer = msg.sender;
        _deployStratWraper();
        _assignStratToVault();
        vm.stopBroadcast();
    }

    function _assignStratToVault() internal {
        VaultManager vaultManager = VaultManager(vaultManagerAddress);
        vaultManager.addReplaceStrategy(vault, indexInVault, replaceStrat, _createStrategy());
    }

    function _createStrategy() internal view returns (Strategy memory) {
        return
            Strategy({strategy: strategy, allocation: Allocation({index: allocationIndex, amount: allocationAmount})});
    }

    function _deployStratWraper() internal {
        strategy = _deployStrat();

        _save(string.concat(stratType, "Strategy"), address(strategy));
    }

    function _save(string memory _name, address _deployed) internal {
        vm.writeJson({json: stdJson.serialize("", _name, _deployed), path: outputPath});
    }

    function _getStratData() internal virtual {
        bytes memory allocationAmountBytes = vm.parseJson(cfgStratJson, ".allocationAmount");
        allocationAmount = abi.decode(allocationAmountBytes, (uint256));

        bytes memory allocationIndexBytes = vm.parseJson(cfgStratJson, ".allocationIndex");
        allocationIndex = abi.decode(allocationIndexBytes, (uint256));

        bytes memory feeRecipientBytes = vm.parseJson(cfgStratJson, ".feeRecipient");
        feeRecipient = abi.decode(feeRecipientBytes, (address));

        bytes memory rewardFeeBytes = vm.parseJson(cfgStratJson, ".rewardFee");
        rewardFee = abi.decode(rewardFeeBytes, (uint256));

        bytes memory indexInVaultBytes = vm.parseJson(cfgStratJson, ".indexInVault");
        indexInVault = abi.decode(indexInVaultBytes, (uint256));

        bytes memory replaceStratBytes = vm.parseJson(cfgStratJson, ".replaceStrat");
        replaceStrat = abi.decode(replaceStratBytes, (bool));
    }

    function _getAddressesData() internal virtual {
        bytes memory vaultManagerAddressBytes = vm.parseJson(cfgJson, ".VaultManager");
        vaultManagerAddress = abi.decode(vaultManagerAddressBytes, (address));
    }

    function _deployStrat() internal virtual returns (IStrategy);
}
