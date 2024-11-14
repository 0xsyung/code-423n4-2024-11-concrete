//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/console.sol";
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
import {VaultManager} from "../src/managers/VaultManager.sol";
import {Errors} from "../src/interfaces/Errors.sol";
import {WithdrawalQueue} from "../src/queue/WithdrawalQueue.sol";

contract VaultManagerTest is Test {
    MockERC20 asset;
    address[] vaultAddresses;

    using Math for uint256;

    VaultFactory factory;
    VaultRegistry vaultRegistry;
    ImplementationRegistry implementationRegistry;
    IVaultDeploymentManager deploymentManager;
    VaultManager vaultManager;

    address implementation;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x5555);

    ImplementationData implementationDataWithoutInit;
    ImplementationData implementationDataWithInit;

    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    error OwnableUnauthorizedAccount(address badOwner);

    event VaultAdded(address indexed vault, bytes32 indexed vaultId);

    function setUp() public {
        vm.label(feeRecipient, "feeRecipient");
        vm.label(admin, "admin");
        implementation = address(new ConcreteMultiStrategyVault());
        asset = new MockERC20("Mock Asset", "MA", 18);
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

    function test_deployVault() public {
        (, Strategy[] memory strategies) = _deployVault(false);
        address[] memory vaults = vaultRegistry.getAllVaults();
        ConcreteMultiStrategyVault vault = ConcreteMultiStrategyVault(vaults[0]);
        assertEq(vault.name(), "Mock Vault", "Name");
        assertEq(vault.symbol(), "MV", "Symbol");
        assertEq(vault.decimals(), 27, "Decimals");

        assertEq(address(vault.asset()), address(asset), "Asset");
        assertEq(vault.owner(), address(vaultManager), "Owner");
        assertEq(vault.feeRecipient(), feeRecipient, "Fee Recipient");

        Strategy[] memory strats = vault.getStrategies();
        assertEq(strats.length, 3, "Length");
        assertEq(address(strats[0].strategy), address(strategies[0].strategy), "Strategy 0");
        assertEq(address(strats[1].strategy), address(strategies[1].strategy), "Strategy 1");
        assertEq(address(strats[2].strategy), address(strategies[2].strategy), "Strategy 2");
        assertTrue(address(vault.withdrawalQueue()) != address(0), "Withdrawal Queue");
    }

    function test_registerNewImplementation() public {
        _deployVault(false);

        ImplementationData memory data = implementationRegistry.getImplementation(keccak256(abi.encode("Test", 1)));

        assertEq(data.implementationAddress, implementation);
        assertTrue(data.initDataRequired);

        address[] memory vaults = implementationRegistry.getHistoricalImplementationAddresses();
        assertEq(vaults.length, 1, "Length");
    }

    function test_removeImplementation() public {
        test_registerNewImplementation();

        vm.prank(admin);
        vaultManager.removeImplementation(keccak256(abi.encode("Test", 1)));

        ImplementationData memory data = implementationRegistry.getImplementation(keccak256(abi.encode("Test", 1)));
        address[] memory allImplementations = implementationRegistry.getHistoricalImplementationAddresses();
        assertEq(data.implementationAddress, address(0), "Implementation");
        assertEq(allImplementations.length, 0, "Historical Implementation");
    }

    function test_pauseVault() public {
        (address vault, ) = _deployVault(false);

        vm.prank(admin);
        vaultManager.pauseVault(vault);

        assertEq(ConcreteMultiStrategyVault(vault).paused(), true, "Vault should be paused");
        assertEq(ConcreteMultiStrategyVault(vault).maxMint(admin), 0, "Max mint should be 0");
    }

    function test_unpauseVault() public {
        (address vault, ) = _deployVault(false);

        vm.prank(admin);
        vaultManager.pauseVault(vault);
        assertEq(ConcreteMultiStrategyVault(vault).paused(), true, "Vault should be paused");

        vm.prank(admin);
        vaultManager.unpauseVault(vault);

        assertEq(ConcreteMultiStrategyVault(vault).paused(), false, "Vault should not be paused");
        assertEq(ConcreteMultiStrategyVault(vault).maxMint(admin), type(uint256).max, "Max mint should be max");
    }

    function test_pauseAllVaults() public {
        (address vault1, ) = _deployVault(false);
        (address vault2, ) = _deployVault(true);
        (address vault3, ) = _deployVault(true);

        vm.prank(admin);
        vaultManager.pauseAllVaults();

        assertEq(ConcreteMultiStrategyVault(vault1).paused(), true, "Vault 1 should be paused");
        assertEq(ConcreteMultiStrategyVault(vault2).paused(), true, "Vault 2 should be paused");
        assertEq(ConcreteMultiStrategyVault(vault3).paused(), true, "Vault 3 should be paused");
    }

    function test_unpauseAllVaults() public {
        (address vault1, ) = _deployVault(false);
        (address vault2, ) = _deployVault(true);
        (address vault3, ) = _deployVault(true);

        vm.prank(admin);
        vaultManager.pauseAllVaults();

        vm.prank(admin);
        vaultManager.unpauseAllVaults();

        assertEq(ConcreteMultiStrategyVault(vault1).paused(), false, "Vault 1 should not be paused");
        assertEq(ConcreteMultiStrategyVault(vault2).paused(), false, "Vault 2 should not be paused");
        assertEq(ConcreteMultiStrategyVault(vault3).paused(), false, "Vault 3 should not be paused");
    }

    function test_setVaultFees() public {
        (address vault, ) = _deployVault(false);

        GraduatedFee[] memory graduatedFees = new GraduatedFee[](4);
        graduatedFees[0] = GraduatedFee({lowerBound: 0, upperBound: 500, fee: 300});
        graduatedFees[1] = GraduatedFee({lowerBound: 501, upperBound: 2000, fee: 1000});
        graduatedFees[2] = GraduatedFee({lowerBound: 2001, upperBound: 5000, fee: 2000});
        graduatedFees[3] = GraduatedFee({lowerBound: 5001, upperBound: 10000, fee: 5000});

        vm.prank(admin);
        vaultManager.setVaultFees(
            vault,
            VaultFees({depositFee: 10, withdrawalFee: 10, protocolFee: 10, performanceFee: graduatedFees})
        );

        VaultFees memory fees = ConcreteMultiStrategyVault(vault).getVaultFees();
        assertEq(fees.depositFee, 10, "Deposit fee should be 10");
        assertEq(fees.withdrawalFee, 10, "Protocol fee should be 10");
        assertEq(fees.protocolFee, 10, "Protocol fee should be 10");
        assertEq(fees.performanceFee.length, 4, "Performance Fee");
    }

    function test_setFeeRecipient() public {
        (address vault, ) = _deployVault(false);

        vm.expectEmit();
        emit FeeRecipientUpdated(feeRecipient, hazel);
        vm.prank(admin);
        vaultManager.setFeeRecipient(vault, hazel);

        assertEq(ConcreteMultiStrategyVault(vault).feeRecipient(), hazel, "Fee recipient should be hazel");
    }

    function test_toggleIdleVault() public {
        (address vault, ) = _deployVault(false);

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        assertEq(ConcreteMultiStrategyVault(vault).vaultIdle(), true, "Vault should be idle");
    }

    function test_addStrategy() public {
        (address vault, ) = _deployVault(false);

        vm.startPrank(admin);
        vaultManager.addReplaceStrategy(vault, 3, false, _createMockStrategy(IERC20(address(asset))));
        assertEq(
            MockERC4626(address(ConcreteMultiStrategyVault(vault).getStrategies()[3].strategy)).balanceOf(
                address(vault)
            ),
            0,
            "Strategy 4 balance"
        );
    }

    function test_changeAllocations() public {
        (address vault, ) = _deployVault(false);

        Allocation[] memory allocations = new Allocation[](3);
        allocations[0] = Allocation({index: 0, amount: 2500});
        allocations[1] = Allocation({index: 0, amount: 2500});
        allocations[2] = Allocation({index: 0, amount: 5000});
        vm.prank(admin);
        vaultManager.changeStrategyAllocations(address(vault), allocations, false);

        Strategy[] memory newStrategies = ConcreteMultiStrategyVault(vault).getStrategies();

        assertEq(newStrategies[0].allocation.amount, 2500, "Strategy 1");
        assertEq(newStrategies[0].allocation.index, 0, "Strategy 1");
        assertEq(newStrategies[1].allocation.amount, 2500, "Strategy 2");
        assertEq(newStrategies[1].allocation.index, 0, "Strategy 2");
        assertEq(newStrategies[2].allocation.amount, 5000, "Strategy 3");
        assertEq(newStrategies[2].allocation.index, 0, "Strategy 3");
    }

    function test_removeStrategy() public {
        (address vault, ) = _deployVault(false);
        vm.startPrank(admin);
        vaultManager.removeStrategy(vault, 2);
        assertEq(ConcreteMultiStrategyVault(vault).getStrategies().length, 2, "Length");
    }

    function test_pushFundsToSingleStrategy() public {
        uint256 amount_ = 1 ether;
        (address vault, Strategy[] memory strats) = _deployVault(false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(vault), hazelsAmount);

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = ConcreteMultiStrategyVault(vault).deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)), 0, "Strategy 2 balance");

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        vm.prank(admin);
        vaultManager.pushFundsToSingleStrategy(vault, 1);

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)), 0, "Strategy 2 balance");
    }

    function test_pushFundsToSingleStrategyWithSpecificAmount() public {
        uint256 amount_ = 1 ether;
        (address vault, Strategy[] memory strats) = _deployVault(false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(vault), hazelsAmount);

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = ConcreteMultiStrategyVault(vault).deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)), 0, "Strategy 2 balance");

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        vm.prank(admin);
        vaultManager.pushFundsToSingleStrategy(vault, 1, amount_.mulDiv(2000, 10_000, Math.Rounding.Floor));

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(2000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)), 0, "Strategy 2 balance");
    }

    function test_pushFundsToAllStrategies() public {
        uint256 amount_ = 1 ether;
        (address vault, Strategy[] memory strats) = _deployVault(false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(vault), hazelsAmount);

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = ConcreteMultiStrategyVault(vault).deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)), 0, "Strategy 2 balance");

        vm.prank(admin);
        vaultManager.toggleIdleVault(vault);

        vm.prank(admin);
        vaultManager.pushFundsToStrategies(vault);

        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );
    }

    function test_pullFundsFromSingleStrategy() public {
        uint256 amount_ = 1e18;
        (address vault, Strategy[] memory strats) = _deployVault(false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(vault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = ConcreteMultiStrategyVault(vault).deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );

        vm.prank(admin);
        vaultManager.pullFundsFromSingleStrategy(vault, 0);

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );
    }

    function test_removeVault() public {
        (address vault, ) = _deployVault(false);

        vm.prank(admin);
        vaultManager.removeVault(vault, keccak256(abi.encode("Test", 1)));

        address[] memory vaults = vaultRegistry.getAllVaults();
        assertEq(vaults.length, 0, "Length");
    }

    function test_removeVaultAndRedeploy() public {
        (address vault, ) = _deployVault(false);

        vm.prank(admin);
        vaultManager.removeVault(vault, keccak256(abi.encode("Test", 1)));

        address[] memory vaults = vaultRegistry.getAllVaults();
        assertEq(vaults.length, 0, "Length");
        vm.warp(block.timestamp + 1);
        _deployVault(true);
        address[] memory newVaults = vaultRegistry.getAllVaults();
        assertEq(newVaults.length, 1, "Length");
    }

    function test_pullFundsFromAllStrategies() public {
        uint256 amount_ = 1e18;
        (address vault, Strategy[] memory strats) = _deployVault(false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(vault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = ConcreteMultiStrategyVault(vault).deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );

        vm.prank(admin);
        vaultManager.pullFundsFromStrategies(vault);

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(vault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(vault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(vault)), 0, "Strategy 2 balance");

        assertEq(asset.balanceOf(address(vault)), amount_, "Vault balance should be equal to amount");
    }

    function test_setMaxDeposit() public {
        (address newVault, ) = _deployVault(false);
        assertEq(ConcreteMultiStrategyVault(newVault).depositLimit(), type(uint256).max, "Deposit limit should be max");

        vm.prank(admin);
        vaultManager.setDepositLimit(newVault, 1e18);
        assertEq(ConcreteMultiStrategyVault(newVault).depositLimit(), 1e18, "Deposit limit should be 1e18");
    }

    function test_setwithdrawlQueue() public {
        (address newVault, ) = _deployVault(false);
        address newQueue = address(0x1234);

        vm.prank(admin);
        vaultManager.setWithdrawalQueue(newVault, newQueue);
        assertEq(
            address(ConcreteMultiStrategyVault(newVault).withdrawalQueue()),
            newQueue,
            "Withdrawal queue should be 0"
        );
    }

    function test_batchClaimRewards() public {
        (address newVault, ) = _deployVault(false);

        vm.prank(admin);
        vaultManager.batchClaimWithdrawal(newVault, 999999);
        //There is no assert because we want to check if the function runs without reverting
    }

    function _deployVault(bool multiple_) internal returns (address, Strategy[] memory) {
        ImplementationData memory data = ImplementationData({
            implementationAddress: implementation,
            initDataRequired: true
        });

        if (!multiple_) {
            vm.prank(admin);
            vaultManager.registerNewImplementation(keccak256(abi.encode("Test", 1)), data);
        }
        (bytes memory initData, Strategy[] memory strategies) = _getInitData();
        vm.prank(admin);
        address vaultAddress = vaultManager.deployNewVault(keccak256(abi.encode("Test", 1)), initData);

        return (vaultAddress, strategies);
    }

    function _createMockStrategy(IERC20 asset_) internal returns (Strategy memory) {
        return
            Strategy({
                strategy: new MockERC4626(asset_, "Mock Shares", "MS"),
                allocation: Allocation({index: 0, amount: 1000}) // 33.3%
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
                address(vaultManager)
            )
        );
        return (initData, strats);
    }

    function _deployController() internal {
        factory = new VaultFactory(address(this));
        vaultRegistry = new VaultRegistry(address(this));
        implementationRegistry = new ImplementationRegistry(address(this));
        vaultManager = new VaultManager(admin);

        deploymentManager = DeploymentManager(
            new DeploymentManager(
                address(vaultManager),
                address(factory),
                address(implementationRegistry),
                address(vaultRegistry)
            )
        );
        factory.transferOwnership(address(deploymentManager));
        vaultRegistry.transferOwnership(address(deploymentManager));
        implementationRegistry.transferOwnership(address(deploymentManager));
        vm.prank(admin);
        vaultManager.adminSetup(IVaultRegistry(vaultRegistry), IVaultDeploymentManager(deploymentManager));
    }

    function test_removeVaultAndRedeployLogicIssue() public {
        for (uint256 index = 0; index < 10; index++) {
            //_deployVault(false)
            ImplementationData memory data = ImplementationData({
                implementationAddress: implementation,
                initDataRequired: true
            });

            vm.prank(admin);
            vaultManager.registerNewImplementation(keccak256(abi.encode("Test", index)), data);

            (bytes memory initData, ) = _getInitData();
            vm.prank(admin);
            vaultAddresses.push(vaultManager.deployNewVault(keccak256(abi.encode("Test", index)), initData));
        }

        vm.prank(admin);
        bytes memory encodedError = abi.encodeWithSelector(Errors.VaultDoesNotExist.selector, vaultAddresses[9]);

        vm.expectRevert(encodedError);
        vaultManager.removeVault(vaultAddresses[9], keccak256(abi.encode("Test", 8))); //admin wanted to remove the vault ID 8, however the vault removed was vault 9.
    }
}
