//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC4626} from "./utils/mocks/MockERC4626.sol";
import {ConcreteMultiStrategyVault} from "../src/vault/ConcreteMultiStrategyVault.sol";
import {Strategy, VaultFees, Allocation, GraduatedFee} from "../src/interfaces/IConcreteMultiStrategyVault.sol";
import {IVaultFactory} from "../src/interfaces/IVaultFactory.sol";
import {IVaultRegistry} from "../src/interfaces/IVaultRegistry.sol";
import {IImplementationRegistry, ImplementationData} from "../src/interfaces/IImplementationRegistry.sol";
import {VaultFactory} from "../src/factories/VaultFactory.sol";
import {VaultRegistry} from "../src/registries/VaultRegistry.sol";
import {ImplementationRegistry} from "../src/registries/ImplementationRegistry.sol";
import {IVaultDeploymentManager} from "../src/interfaces/IVaultDeploymentManager.sol";
import {DeploymentManager} from "../src/managers/DeploymentManager.sol";
import {Errors} from "../src/interfaces/Errors.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

contract DeploymentAndRegistryTest is Test {
    MockERC20 asset;

    VaultFactory factory;
    VaultRegistry vaultRegistry;
    ImplementationRegistry implementationRegistry;
    IVaultDeploymentManager deploymentManager;

    address implementation;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);

    ImplementationData implementationDataWithoutInit;
    ImplementationData implementationDataWithInit;

    event VaultAdded(address indexed vault, bytes32 indexed vaultId);

    function setUp() public {
        vm.label(feeRecipient, "feeRecipient");
        vm.label(admin, "admin");
        implementation = address(new ConcreteMultiStrategyVault());
        asset = new MockERC20("Mock Vault", "MV", 18);
        _deployController();

        implementationDataWithoutInit = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: false
        });
        implementationDataWithInit = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
    }

    function test_deployment() public view {
        assertFalse(address(deploymentManager) == address(0));
        assertEq(factory.owner(), address(deploymentManager));
        assertEq(vaultRegistry.owner(), address(deploymentManager));
        assertEq(implementationRegistry.owner(), address(deploymentManager));
    }

    function test_addImplementation() public {
        deploymentManager.addImplementation(keccak256(abi.encode("Test", 1)), implementationDataWithoutInit);
        ImplementationData memory data = implementationRegistry.getImplementation(keccak256(abi.encode("Test", 1)));

        assertEq(data.implementationAddress, implementation);
        assertFalse(data.initDataRequired);

        address[] memory vaults = implementationRegistry.getHistoricalImplementationAddresses();
        assertEq(vaults.length, 1, "Length");
    }

    function test_removeImplementation() public {
        test_addImplementation();
        // address[] memory _allImplementations = implementationRegistry.getHistoricalImplementationAddresses();
        deploymentManager.removeImplementation(keccak256(abi.encode("Test", 1)));
        ImplementationData memory data = implementationRegistry.getImplementation(keccak256(abi.encode("Test", 1)));
        address[] memory allImplementations = implementationRegistry.getHistoricalImplementationAddresses();
        assertEq(data.implementationAddress, address(0), "Implementation");
        assertEq(allImplementations.length, 0, "Historical Implementation");
    }

    function testFail_addImplementationAlreadyExists() public {
        test_addImplementation();
        vm.expectRevert(Errors.ImplementationAlreadyExists.selector);
        deploymentManager.addImplementation(keccak256(abi.encode("Test", 1)), implementationDataWithoutInit);
    }

    function testFail_removeImplementationDoesntExist() public {
        vm.expectRevert(Errors.ImplementationDoesNotExist.selector);
        deploymentManager.removeImplementation(keccak256(abi.encode("Failure", 1)));
    }

    function test_deployNewVaultNoInitData() public {
        test_addImplementation();
        vm.expectEmit(false, true, true, true);
        emit VaultAdded(address(0), keccak256(abi.encode("Test", 1)));
        deploymentManager.deployNewVault(keccak256(abi.encode("Test", 1)), bytes(""));

        address[] memory vaults = vaultRegistry.getAllVaults();
        address[] memory vaultsById = vaultRegistry.getVaultsByImplementationId(keccak256(abi.encode("Test", 1)));
        assertEq(vaults.length, 1);
        assertEq(vaultsById.length, 1);
    }

    function testFail_deployNewVaultBadImplementationAddress() public {
        ImplementationData memory badData = ImplementationData({
            implementationAddress: address(0),
            initDataRequired: false
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), badData);
        vm.expectRevert(Errors.InvalidImplementation.selector);
        deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), bytes(""));
    }

    function test_ownership() public {
        vm.prank(admin);
        vm.expectRevert();
        deploymentManager.addImplementation(keccak256(abi.encode("Test", 1)), implementationDataWithoutInit);

        test_addImplementation();
        vm.prank(admin);

        vm.expectRevert();
        deploymentManager.removeImplementation(keccak256(abi.encode("Test", 1)));
    }

    function test_deployVaultWithInit() public {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), data);
        (bytes memory initData, Strategy[] memory strategies) = _getInitData();
        deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);

        address[] memory vaults = vaultRegistry.getAllVaults();
        ConcreteMultiStrategyVault vault = ConcreteMultiStrategyVault(vaults[0]);
        assertEq(vault.name(), "Mock Vault", "Name");
        assertEq(vault.symbol(), "MV", "Symbol");
        assertEq(vault.decimals(), 27, "Decimals");

        assertEq(address(vault.asset()), address(asset), "Asset");
        assertEq(vault.owner(), admin, "Owner");
        assertEq(vault.feeRecipient(), feeRecipient, "Fee Recipient");

        Strategy[] memory strats = vault.getStrategies();
        assertEq(strats.length, 3, "Length");
        assertEq(address(strats[0].strategy), address(strategies[0].strategy), "Strategy 0");
        assertEq(address(strats[1].strategy), address(strategies[1].strategy), "Strategy 1");
        assertEq(address(strats[2].strategy), address(strategies[2].strategy), "Strategy 2");
    }

    function test_removeVaultFromImplementation() public {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), data);
        (bytes memory initData, ) = _getInitData();
        deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);

        address[] memory vaults = vaultRegistry.getAllVaults();
        ConcreteMultiStrategyVault vault = ConcreteMultiStrategyVault(vaults[0]);
        address[] memory vaultsByToken = vaultRegistry.getVaultsByToken(address(asset)); // No vaults for this
        assertEq(vaultsByToken.length, 1, "Vaults by token before length ");
        deploymentManager.removeVault(address(vault), keccak256(abi.encode("Test2", 1)));
        address[] memory newVaults = vaultRegistry.getAllVaults();

        address[] memory newVaultsByToken = vaultRegistry.getVaultsByToken(address(asset)); // No vaults for this
        assertEq(newVaultsByToken.length, 0, "Vaults by token length");
        assertEq(newVaults.length, 0, "Vaults length");
    }

    function test_deployWithBadInitData() public {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), data);
        vm.expectRevert(Errors.VaultDeployInitFailed.selector);
        deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), bytes(""));
    }

    function test_setTotalVaultsAllowed() public {
        vm.prank(address(deploymentManager));
        vaultRegistry.setVaultByTokenLimit(9);
        assertEq(vaultRegistry.vaultByTokenLimit(), 9);
    }

    function test_setVaultLimitByToken() public {
        vm.prank(address(deploymentManager));
        vaultRegistry.setVaultByTokenLimit(11);
        assertEq(vaultRegistry.vaultByTokenLimit(), 11);
    }

    function test_deploymentManagerSetTotalVaultsAllowed() public {
        deploymentManager.setVaultByTokenLimit(9);
        assertEq(vaultRegistry.vaultByTokenLimit(), 9);
    }

    function test_deploymentManagerSetVaultLimitByToken() public {
        deploymentManager.setVaultByTokenLimit(11);
        assertEq(vaultRegistry.vaultByTokenLimit(), 11);
    }

    function testfail_deploymentManagerSetTotalVaultsAllowedNotOwner() public {
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0x1));
        vm.expectRevert(encodedError);
        vm.prank(address(0x1));
        deploymentManager.setVaultByTokenLimit(9);
    }

    function testfail_deploymentManagerSetVaultLimitByTokenNotOwner() public {
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0x1));
        vm.expectRevert(encodedError);
        vm.prank(address(0x1));
        deploymentManager.setTotalVaultsAllowed(9);
    }

    function testfail_setTotalVaultsAllowedNotOwner() public {
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this));
        vm.expectRevert(encodedError);
        vaultRegistry.setVaultByTokenLimit(9);
    }

    function testfail_setVaultLimitByTokenNotOwner() public {
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this));
        vm.expectRevert(encodedError);
        vaultRegistry.setTotalVaultsAllowed(9);
    }

    function testfail_ExceedTotalVaultsAllowedWhenupdatingLimit() public {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), data);
        (bytes memory initData, ) = _getInitData();
        for (uint256 i = 0; i < 10; i++) {
            deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);
        }
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.TotalVaultsAllowedExceeded.selector,
            vaultRegistry.getAllVaults().length
        );
        vm.expectRevert(encodedError);
        vm.prank(address(deploymentManager));
        vaultRegistry.setTotalVaultsAllowed(9);
    }

    function testfail_ExceedTotalVaultsAllowed() public {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), data);
        (bytes memory initData, ) = _getInitData();
        for (uint256 i = 0; i < 10; i++) {
            deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);
        }
        vm.prank(address(deploymentManager));
        vaultRegistry.setTotalVaultsAllowed(10);
        uint256 totalVaultsAllowed = vaultRegistry.totalVaultsAllowed();
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.TotalVaultsAllowedExceeded.selector,
            totalVaultsAllowed + 1
        );
        vm.expectRevert(encodedError);
        deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);
    }

    function testfail_ExceedVaultByTokenLimit() public {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });
        deploymentManager.addImplementation(keccak256(abi.encode("Test2", 1)), data);
        (bytes memory initData, ) = _getInitData();
        for (uint256 i = 0; i < 10; i++) {
            deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);
        }
        vm.prank(address(deploymentManager));
        vaultRegistry.setVaultByTokenLimit(10);
        uint256 vaultByTokenLimit = vaultRegistry.vaultByTokenLimit();
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.VaultByTokenLimitExceeded.selector,
            address(asset),
            vaultByTokenLimit + 1
        );
        vm.expectRevert(encodedError);
        deploymentManager.deployNewVault(keccak256(abi.encode("Test2", 1)), initData);
    }

    function _deployController() internal {
        factory = new VaultFactory(address(this));
        vaultRegistry = new VaultRegistry(address(this));
        implementationRegistry = new ImplementationRegistry(address(this));

        deploymentManager = DeploymentManager(
            new DeploymentManager(
                address(this),
                address(factory),
                address(implementationRegistry),
                address(vaultRegistry)
            )
        );
        factory.transferOwnership(address(deploymentManager));
        vaultRegistry.transferOwnership(address(deploymentManager));
        implementationRegistry.transferOwnership(address(deploymentManager));
    }

    function _createMockStrategy(IERC20 asset_) internal returns (Strategy memory) {
        return
            Strategy({
                strategy: new MockERC4626(asset_, "Mock Shares", "MS"),
                allocation: Allocation({index: 0, amount: 3333}) // 33.3%
            });
    }

    function _getInitData() internal returns (bytes memory, Strategy[] memory) {
        Strategy[] memory strats = new Strategy[](3);
        strats[0] = _createMockStrategy(IERC20(address(asset)));
        strats[1] = _createMockStrategy(IERC20(address(asset)));
        strats[2] = _createMockStrategy(IERC20(address(asset)));
        GraduatedFee[] memory graduatedFees = new GraduatedFee[](4);
        graduatedFees[0] = GraduatedFee({lowerBound: 0, upperBound: 500, fee: 300});
        graduatedFees[1] = GraduatedFee({lowerBound: 501, upperBound: 2000, fee: 1000});
        graduatedFees[2] = GraduatedFee({lowerBound: 2001, upperBound: 5000, fee: 2000});
        graduatedFees[3] = GraduatedFee({lowerBound: 5001, upperBound: 10000, fee: 5000});
        bytes memory initData = abi.encodeCall(
            ConcreteMultiStrategyVault.initialize,
            (
                IERC20(address(asset)),
                "Mock Vault",
                "MV",
                strats,
                feeRecipient,
                VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: graduatedFees}),
                type(uint256).max,
                admin
            )
        );
        return (initData, strats);
    }
}
