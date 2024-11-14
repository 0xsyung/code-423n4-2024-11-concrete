//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {VaultManager} from "../src/managers/VaultManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strategy, VaultFees, Allocation, GraduatedFee} from "../src/interfaces/IConcreteMultiStrategyVault.sol";
import {ConcreteMultiStrategyVault} from "../src/vault/ConcreteMultiStrategyVault.sol";

import {IStrategy} from "../src/interfaces/IStrategy.sol";
import {Deployer} from "./Deployer.sol";
import {DeployConfig} from "./DeployConfig.s.sol";

contract DeployNewVault is Deployer {
    struct VaultImplementation {
        uint256 index;
        string name;
    }

    string underlyingCurrency;
    address underlyingAddress;
    uint256 depositFee;
    uint256 withdrawalFee;
    uint256 protocolFee;

    VaultManager vaultManager;
    VaultImplementation vaultImplementation;
    GraduatedFee[] graduatedFees;
    Strategy[] strategies;
    address implementation;
    DeployConfig cfg;
    DeployConfig cfgAddresses;
    string outputPath;

    address public deployer;

    function setUp() public virtual override {
        string memory deploymentContext = _getDeploymentContext();
        string memory path = string.concat(
            "./deploy-config/vault/",
            deploymentContext,
            ".",
            vm.envString("CURRENCY"),
            ".json"
        );
        cfg = new DeployConfig(path);
        console.log("Deployment Context: %s", path);

        string memory path2 = string.concat("./deploy-config/", deploymentContext, ".EarnCoreAddresses.json");
        cfgAddresses = new DeployConfig(path2); // This can be used to read anything from config json
    }

    function run() external {
        _getVaultData();
        _getAddressesData();
        string memory deploymentContext = _getDeploymentContext();
        console.log("Deployment Context: %s", deploymentContext);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        outputPath = string.concat(
            "./deploy-config/vault/",
            deploymentContext,
            ".",
            vm.envString("CURRENCY"),
            ".output.json"
        );
        console.log("Output Path: %s", outputPath);
        vm.startBroadcast(deployerPrivateKey);
        deployer = msg.sender;
        _deployVault();
        vm.stopBroadcast();
    }

    function _deployVault() internal {
        bytes memory initData = _getInitData();
        address vaultAddress = vaultManager.deployNewVault(
            keccak256(abi.encode(vaultImplementation.name, vaultImplementation.index)),
            initData
        );
        _save(string.concat(underlyingCurrency, " Vault Arbitrum"), vaultAddress, outputPath);
    }

    function _getInitData() internal view returns (bytes memory) {
        Strategy[] memory strats = new Strategy[](0);

        bytes memory initData = abi.encodeCall(
            ConcreteMultiStrategyVault.initialize,
            (
                IERC20(underlyingAddress),
                string.concat(underlyingCurrency, "-Vault"),
                string.concat("CT-", underlyingCurrency),
                strats,
                deployer,
                VaultFees({
                    depositFee: uint64(depositFee),
                    withdrawalFee: uint64(withdrawalFee),
                    protocolFee: uint64(protocolFee),
                    performanceFee: graduatedFees
                }),
                type(uint256).max,
                address(vaultManager)
            )
        );
        return initData;
    }

    function _getAddressesData() internal {
        string memory json = cfgAddresses._json();
        bytes memory vaultManagerAddressBytes = vm.parseJson(json, ".VaultManager");
        vaultManager = VaultManager(abi.decode(vaultManagerAddressBytes, (address)));
    }

    function _getVaultData() internal {
        string memory json = cfg._json();

        bytes memory underlyingCurrencyBytes = vm.parseJson(json, ".underlyingCurrency");
        underlyingCurrency = abi.decode(underlyingCurrencyBytes, (string));

        bytes memory underlyingAddressBytes = vm.parseJson(json, ".underlyingAddress");
        underlyingAddress = abi.decode(underlyingAddressBytes, (address));

        bytes memory depositFeeBytes = vm.parseJson(json, ".depositFee");
        depositFee = abi.decode(depositFeeBytes, (uint256));

        bytes memory withdrawalFeeBytes = vm.parseJson(json, ".withdrawalFee");
        withdrawalFee = abi.decode(withdrawalFeeBytes, (uint256));

        bytes memory protocolFeeBytes = vm.parseJson(json, ".protocolFee");
        protocolFee = abi.decode(protocolFeeBytes, (uint256));

        bytes memory vaultImplementationBytes = vm.parseJson(json, ".vaultImplementation");
        vaultImplementation = abi.decode(vaultImplementationBytes, (VaultImplementation));

        GraduatedFee[] memory graduatedFeesMem = abi.decode(vm.parseJson(json, ".performanceFees"), (GraduatedFee[]));
        for (uint256 i = 0; i < graduatedFeesMem.length; i++) {
            graduatedFees.push(graduatedFeesMem[i]);
        }

        //Strategy
        string[] memory strategiesArray = vm.parseJsonStringArray(json, ".strategies");

        uint256 len = strategiesArray.length;
        for (uint256 i = 0; i < len; i++) {
            bytes memory stratBytes = vm.parseJson(
                json,
                string.concat(".strategies[", Strings.toString(i), "].strategy")
            );
            address stratAddress = abi.decode(stratBytes, (address));

            bytes memory allocBytes = vm.parseJson(
                json,
                string.concat(".strategies[", Strings.toString(i), "].allocation")
            );
            Allocation memory alloc = abi.decode(allocBytes, (Allocation));

            strategies.push(Strategy({strategy: IStrategy(stratAddress), allocation: alloc}));
        }
    }
}
