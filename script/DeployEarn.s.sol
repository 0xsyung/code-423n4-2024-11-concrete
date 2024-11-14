//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IImplementationRegistry, ImplementationData} from "../src/interfaces/IImplementationRegistry.sol";
import {VaultFactory} from "../src/factories/VaultFactory.sol";
import {VaultRegistry} from "../src/registries/VaultRegistry.sol/";
import {ImplementationRegistry} from "../src/registries/ImplementationRegistry.sol";
import {VaultManager} from "../src/managers/VaultManager.sol";
import {DeploymentManager} from "../src/managers/DeploymentManager.sol";
import {MockERC20} from "../test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "../test/utils/mocks/MockERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strategy, VaultFees, Allocation, GraduatedFee} from "../src/interfaces/IConcreteMultiStrategyVault.sol";
import {ConcreteMultiStrategyVault} from "../src/vault/ConcreteMultiStrategyVault.sol";
import {ClaimRouter} from "../src/claimRouter/ClaimRouter.sol";
import {TokenRegistry} from "../src/registries/TokenRegistry.sol";

import {IVaultRegistry} from "../src/interfaces/IVaultRegistry.sol";
import {IVaultDeploymentManager} from "../src/interfaces/IVaultDeploymentManager.sol";
import {DeployConfig} from "./DeployConfig.s.sol";
import {Deployer} from "./Deployer.sol";

contract DeployEarn is Deployer {
    DeployConfig cfg;
    VaultFactory factory;
    VaultRegistry vaultRegistry;
    ImplementationRegistry implementationRegistry;
    VaultManager vaultManager;
    DeploymentManager deploymentManager;
    ClaimRouter claimRouter;
    TokenRegistry tokenRegistry;
    address vaultImplementation;
    address treasury;
    address[] tokenCascade;
    address[] blueprints;

    string outputPath;

    address public deployer;
    string deploymentContext;
    bytes32 public constant BLUEPRINT_ROLE = keccak256("BLUEPRINT_ROLE");

    function setUp() public virtual override {
        deploymentContext = _getDeploymentContext();
        console.log("Deployment Context: %s", deploymentContext);
        string memory path = string.concat("./deploy-config/", deploymentContext, ".json");
        cfg = new DeployConfig(path); // This can be used to read anything from config json
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        outputPath = string.concat("./deploy-config/", deploymentContext, ".EarnCoreAddresses.json");
        vm.startBroadcast(deployerPrivateKey);
        deployer = msg.sender;
        vaultImplementation = address(new ConcreteMultiStrategyVault());
        _deployController();
        vm.stopBroadcast();
    }

    function _deployController() internal {
        _getConfigData();

        console.log("Deployer: %s", deployer);
        console.log("Address - This", address(this));

        factory = new VaultFactory(deployer);
        _save("VaultFactory", address(factory), outputPath);

        vaultRegistry = new VaultRegistry(deployer);
        _save("VaultRegistry", address(vaultRegistry), outputPath);

        implementationRegistry = new ImplementationRegistry(deployer);
        _save("ImplementationRegistry", address(implementationRegistry), outputPath);

        vaultManager = new VaultManager(deployer);
        _save("VaultManager", address(vaultManager), outputPath);

        deploymentManager = DeploymentManager(
            new DeploymentManager(
                address(vaultManager),
                address(factory),
                address(implementationRegistry),
                address(vaultRegistry)
            )
        );
        _save("DeploymentManager", address(deploymentManager), outputPath);

        factory.transferOwnership(address(deploymentManager));
        vaultRegistry.transferOwnership(address(deploymentManager));
        implementationRegistry.transferOwnership(address(deploymentManager));
        vaultManager.adminSetup(IVaultRegistry(vaultRegistry), IVaultDeploymentManager(deploymentManager));

        ImplementationData memory data = ImplementationData({
            implementationAddress: vaultImplementation,
            initDataRequired: true
        });

        vaultManager.registerNewImplementation(keccak256(abi.encode("VaultBase", 1)), data);
        _save("VaultImplementation", vaultImplementation, outputPath);

        tokenRegistry = new TokenRegistry(deployer, treasury);
        _save("TokenRegistry", address(tokenRegistry), outputPath);

        claimRouter = new ClaimRouter(
            deployer,
            address(vaultRegistry),
            address(tokenRegistry),
            blueprints,
            tokenCascade
        );
        _save("ClaimRouter", address(claimRouter), outputPath);
    }

    function _getConfigData() internal {
        string memory json = cfg._json();

        bytes memory treasuryBytes = vm.parseJson(json, ".treasury");
        treasury = abi.decode(treasuryBytes, (address));

        string[] memory tokenCascadeArray = vm.parseJsonStringArray(json, ".tokenCascade");

        uint256 len = tokenCascadeArray.length;
        for (uint256 i = 0; i < len; i++) {
            bytes memory tokenBytes = vm.parseJson(json, string.concat(".tokenCascade[", Strings.toString(i), "]"));
            address tokenAddress = abi.decode(tokenBytes, (address));

            tokenCascade.push(tokenAddress);
        }

        string[] memory blueprintsArray = vm.parseJsonStringArray(json, ".tokenCascade");

        len = blueprintsArray.length;
        for (uint256 i = 0; i < len; i++) {
            bytes memory blueprintnBytes = vm.parseJson(
                json,
                string.concat(".extraBlueprints[", Strings.toString(i), "]")
            );
            address tokenAddress = abi.decode(blueprintnBytes, (address));

            blueprints.push(tokenAddress);
        }
    }
}
