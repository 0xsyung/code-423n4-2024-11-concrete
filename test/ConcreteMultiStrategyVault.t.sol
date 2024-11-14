//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC4626} from "./utils/mocks/MockERC4626.sol";
import {MockERC4626Queue} from "./utils/mocks/MockERC4626Queue.sol";
import {MockERC4626Protect} from "./utils/mocks/MockERC4626Protect.sol";
import {ConcreteMultiStrategyVault} from "../src/vault/ConcreteMultiStrategyVault.sol";
import {IMockStrategy} from "../src/interfaces/IMockStrategy.sol";
import {Strategy, VaultFees, Allocation, GraduatedFee} from "../src/interfaces/IConcreteMultiStrategyVault.sol";
import {IStrategy, ReturnedRewards} from "../src/interfaces/IStrategy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../src/interfaces/Errors.sol";
import {WithdrawalQueue} from "../src/queue/WithdrawalQueue.sol";

contract ConcreteMultiStrategyVaultTest is Test {
    using Math for uint256;

    uint256 public constant PRECISION = 1e36;
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    MockERC20 asset;
    Strategy[] strategies;
    ConcreteMultiStrategyVault vault;

    GraduatedFee[] graduatedFees;
    GraduatedFee[] zeroFees;

    address strategyImplementation;
    address implementation;

    uint256 internal constant ONE = 1e18;
    uint256 SECONDS_PER_YEAR = 365.25 days;

    address feeRecipient = address(0x1111);
    address jimmy = address(0x2222);
    address hazel = address(0x3333);
    address admin = address(0x4444);
    address ellie = address(0x5555);

    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ToggleVaultIdle(bool pastValue, bool newValue);
    event StrategyAdded(address newStrategy);
    event StrategyRemoved(address oldStrategy);
    event DepositLimitSet(uint256 limit);
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        vm.label(feeRecipient, "feeRecipient");
        vm.label(jimmy, "jimmy");
        vm.label(hazel, "hazel");
        // Example performanceFee: [{0000, 500, 300}, {501, 2000, 1000}, {2001, 5000, 2000}, {5001, 10000, 5000}]

        graduatedFees.push(GraduatedFee({lowerBound: 0, upperBound: 500, fee: 300}));
        graduatedFees.push(GraduatedFee({lowerBound: 501, upperBound: 2000, fee: 1000}));
        graduatedFees.push(GraduatedFee({lowerBound: 2001, upperBound: 5000, fee: 2000}));
        graduatedFees.push(GraduatedFee({lowerBound: 5001, upperBound: 10000, fee: 5000}));

        zeroFees.push(GraduatedFee({lowerBound: 0, upperBound: 10000, fee: 0}));

        asset = new MockERC20("Mock Asset", "MA", 18);
        strategyImplementation = address(new MockERC4626(IERC20(address(asset)), "Mock Shares", "MS"));

        strategies.push(_createMockStrategy(IERC20(address(asset)), false));
        strategies.push(_createMockProstotectStrategy(IERC20(address(asset)), false));

        implementation = address(new ConcreteMultiStrategyVault());
        address vaultAddress = Clones.clone(implementation);

        vault = ConcreteMultiStrategyVault(vaultAddress);

        vault.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            strategies,
            feeRecipient,
            VaultFees({depositFee: 500, withdrawalFee: 100, protocolFee: 300, performanceFee: graduatedFees}),
            type(uint256).max,
            admin
        );
    }

    function test_metadata() public view {
        assertEq(vault.name(), "Mock Vault", "Name");
        assertEq(vault.symbol(), "MV", "Symbol");
        assertEq(vault.decimals(), 27, "Decimals");

        assertEq(address(vault.asset()), address(asset), "Asset");
        assertEq(vault.owner(), admin, "Owner");
        assertEq(vault.feeRecipient(), feeRecipient, "Fee Recipient");
        assertFalse(vault.protectStrategy() == address(0), "Protect Strategy");
        Strategy[] memory strats = vault.getStrategies();
        assertEq(strats.length, 2, "Length");
        assertEq(address(strats[0].strategy), address(strategies[0].strategy), "Strategy 0");
        assertEq(address(strats[1].strategy), address(strategies[1].strategy), "Strategy 1");

        VaultFees memory fees = vault.getVaultFees();
        assertEq(fees.depositFee, 500, "Deposit Fee");
        assertEq(fees.withdrawalFee, 100, "Withdrawal Fee");
        assertEq(fees.protocolFee, 300, "Protocol Fee");
        assertEq(fees.performanceFee.length, 4, "Performance Fee");

        assertEq(asset.allowance(address(vault), address(strategies[0].strategy)), type(uint256).max, "Allowance 0");
        assertEq(asset.allowance(address(vault), address(strategies[1].strategy)), type(uint256).max, "Allowance 1");

        assertFalse(vault.vaultIdle());

        assertEq(fees.performanceFee[0].fee, 300, "Performance Fee 0");
        assertEq(fees.performanceFee[1].fee, 1000, "Performance Fee 1");
        assertEq(fees.performanceFee[2].fee, 2000, "Performance Fee 2");
        assertEq(fees.performanceFee[3].fee, 5000, "Performance Fee 3");
    }

    function testfail_zero_asset() public {
        address vaultAddress = Clones.clone(implementation);
        ConcreteMultiStrategyVault v = ConcreteMultiStrategyVault(vaultAddress);
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidAssetAddress.selector);
        vm.expectRevert(encodedError);
        v.initialize(
            IERC20(address(0)),
            "Mock Vault",
            "MV",
            strategies,
            feeRecipient,
            VaultFees({depositFee: 500, withdrawalFee: 100, protocolFee: 300, performanceFee: graduatedFees}),
            type(uint256).max,
            admin
        );
    }

    function testfail_strategy_asset_mismatch() public {
        address vaultAddress = Clones.clone(implementation);

        ConcreteMultiStrategyVault v = ConcreteMultiStrategyVault(vaultAddress);
        Strategy[] memory badStrategies = new Strategy[](1);
        badStrategies[0] = _createMockProstotectStrategy(IERC20(address(asset)), false);
        bytes memory encodedError = abi.encodeWithSelector(Errors.VaultAssetMismatch.selector);
        vm.expectRevert(encodedError);
        v.initialize(
            IERC20(address(0x1)),
            "Mock Vault",
            "MV",
            badStrategies,
            feeRecipient,
            VaultFees({depositFee: 500, withdrawalFee: 100, protocolFee: 300, performanceFee: graduatedFees}),
            100,
            admin
        );
    }

    function testfail_strategy_protect_duplicated() public {
        address vaultAddress = Clones.clone(implementation);

        ConcreteMultiStrategyVault v = ConcreteMultiStrategyVault(vaultAddress);
        Strategy[] memory badStrategies2 = new Strategy[](3);
        badStrategies2[0] = _createMockStrategy(IERC20(address(asset)), false);
        badStrategies2[1] = _createMockProstotectStrategy(IERC20(address(asset)), false);
        badStrategies2[2] = _createMockProstotectStrategy(IERC20(address(asset)), false);
        bytes memory encodedError = abi.encodeWithSelector(Errors.MultipleProtectStrat.selector);
        vm.expectRevert(encodedError);
        v.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            badStrategies2,
            feeRecipient,
            VaultFees({depositFee: 500, withdrawalFee: 100, protocolFee: 300, performanceFee: graduatedFees}),
            type(uint256).max,
            admin
        );
    }

    function testfail_strategy_address_zero() public {
        address vaultAddress = Clones.clone(implementation);

        ConcreteMultiStrategyVault v = ConcreteMultiStrategyVault(vaultAddress);
        Strategy[] memory badStrategies = new Strategy[](1);
        badStrategies[0] = _createMockProstotectStrategy(IERC20(address(asset)), false);
        vm.expectRevert();
        v.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            new Strategy[](1),
            feeRecipient,
            VaultFees({depositFee: 500, withdrawalFee: 100, protocolFee: 300, performanceFee: graduatedFees}),
            100,
            admin
        );
    }

    function testFail_fee_too_high() public {
        ConcreteMultiStrategyVault v = new ConcreteMultiStrategyVault();
        v.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            strategies,
            feeRecipient,
            VaultFees({depositFee: 1e18, withdrawalFee: 0, protocolFee: 0, performanceFee: zeroFees}),
            100,
            admin
        );
    }

    function testFail_feeRecipient_invalid() public {
        ConcreteMultiStrategyVault v = new ConcreteMultiStrategyVault();
        v.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            strategies,
            address(0),
            VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: zeroFees}),
            100,
            admin
        );
    }

    function test_deposit_redeem_no_fees(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000_000);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e9;
        //TODO: Make sure that this is actually just ensuring 18 decimal places...
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelsAmount * 1e9, hazelShares, "Shares with Offset");
        assertEq(preDepositBalance - amount_, asset.balanceOf(hazel), "Pre-deposit balance");
        assertEq(newVault.balanceOf(hazel), hazelShares, "Hazels balance in vault");
        assertEq(newVault.totalAssets(), hazelsAmount, "Total assets");
        assertEq(newVault.totalSupply(), hazelShares, "Total supply");
        assertEq(newVault.previewDeposit(hazelsAmount), hazelShares, "Preview deposit");
        assertEq(newVault.previewWithdraw(hazelsAmount), hazelShares, "Preview withdraw");
        assertEq(newVault.convertToAssets(newVault.balanceOf(hazel)), hazelsAmount);
        assertEq(asset.balanceOf(hazel), 0, "Hazels asset balance after deposit");
        //TODO: Handle dust. This should be zero if we sweep all the dust in the contract

        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[0].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[1].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[2].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 2 balance"
        );

        vm.prank(hazel);
        newVault.withdraw(hazelsAmount, hazel, hazel);

        assertEq(asset.balanceOf(hazel), amount_, "Hazels asset Balance");
        assertEq(newVault.balanceOf(hazel), 0, "Hazels balance in vault");
        assertEq(newVault.totalAssets(), 0, "Total assets");
        assertEq(newVault.totalSupply(), 0, "Total supply");
        assertEq(asset.balanceOf(address(newVault)), 0, "Actual vault balance");

        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");
    }

    function test_multiple_deposits(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        uint256 jimmysAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        asset.mint(jimmy, jimmysAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);
        vm.prank(jimmy);
        asset.approve(address(newVault), jimmysAmount);

        uint256 preDepositBalanceHazel = asset.balanceOf(hazel);
        assertEq(preDepositBalanceHazel, amount_);
        uint256 preDepositBalanceJimmy = asset.balanceOf(jimmy);
        assertEq(preDepositBalanceJimmy, amount_);

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        vm.prank(jimmy);
        uint256 jimmyShares = newVault.deposit(jimmysAmount, jimmy);

        assertEq(hazelsAmount * 1e9, hazelShares, "Shares with Offset");
        assertEq(preDepositBalanceHazel - amount_, asset.balanceOf(hazel), "Pre-deposit balance");
        assertEq(newVault.balanceOf(hazel), hazelShares, "Hazels balance in vault");
        assertEq(newVault.totalAssets(), hazelsAmount + jimmysAmount, "Total assets");
        assertEq(newVault.totalSupply(), hazelShares + jimmyShares, "Total supply");
        assertEq(newVault.previewDeposit(hazelsAmount), hazelShares, "Preview deposit");
        assertEq(newVault.previewWithdraw(hazelsAmount), hazelShares, "Preview withdraw");
        assertEq(newVault.convertToAssets(newVault.balanceOf(hazel)), hazelsAmount);

        //jimmy
        assertEq(jimmysAmount * 1e9, jimmyShares, "Shares with Offset");
        assertEq(preDepositBalanceJimmy - amount_, asset.balanceOf(jimmy), "Pre-deposit balance");
        assertEq(newVault.balanceOf(jimmy), jimmyShares, "Jimmy balance in vault");
        assertEq(newVault.totalAssets(), hazelsAmount + jimmysAmount, "Total assets");
        assertEq(newVault.totalSupply(), hazelShares + jimmyShares, "Total supply");
        assertEq(newVault.previewDeposit(jimmysAmount), jimmyShares, "Preview deposit");
        assertEq(newVault.previewWithdraw(jimmysAmount), jimmyShares, "Preview withdraw");
        assertEq(newVault.convertToAssets(newVault.balanceOf(jimmy)), jimmysAmount);

        vm.prank(hazel);
        newVault.withdraw(hazelsAmount, hazel, hazel);

        // Check that Hazels share balance is zero, and Jimmy has a balance still
        assertEq(newVault.balanceOf(hazel), 0, "Hazels balance in vault");
        assertEq(newVault.balanceOf(jimmy), jimmyShares, "Jimmy balance in vault");
        assertEq(asset.balanceOf(jimmy), 0, "Jimmy asset balance");

        assertEq(asset.balanceOf(hazel), hazelsAmount, "Hazels asset balance");
        assertEq(newVault.totalAssets(), amount_, "Total assets");
        assertEq(newVault.totalSupply(), jimmyShares, "Total supply");

        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );

        // Check that Jimmy can withdraw
        vm.prank(jimmy);
        newVault.withdraw(jimmysAmount, jimmy, jimmy);
        assertEq(newVault.balanceOf(jimmy), 0, "Jimmy balance in vault");
        assertEq(asset.balanceOf(jimmy), jimmysAmount, "Jimmy asset balance");
    }

    function testFail_zeroDeposit() public {
        vault.deposit(0, address(this));
    }

    function testFail_depositWithNoApproval() public {
        vault.deposit(1 ether, address(this));
    }

    function testFail_withdrawMaxViolation() public {
        asset.mint(address(this), 0.5 ether);
        vault.deposit(0.5 ether, address(this));
        vault.withdraw(1 ether, address(this), address(this));
    }

    function test_mintRedeem() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        uint256 amount_ = 1e18;
        uint256 jimmyShareAmount = amount_;
        asset.mint(jimmy, jimmyShareAmount);

        vm.prank(jimmy);
        asset.approve(address(newVault), jimmyShareAmount);

        vm.prank(jimmy);
        uint256 jimmyAssetAmount = newVault.mint(jimmyShareAmount, jimmy);

        assertApproxEqAbs(newVault.previewDeposit(jimmyAssetAmount), jimmyShareAmount, 1e9, "Preview Deposit");

        assertEq(newVault.balanceOf(jimmy), jimmyShareAmount, "Jimmy balance in vault");
        assertEq(newVault.totalAssets(), jimmyAssetAmount, "Total assets");
    }

    function test_operateOnBehalfOf() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        asset.mint(jimmy, 1 ether);
        asset.mint(hazel, 1 ether);

        vm.prank(hazel);
        asset.approve(address(newVault), 1 ether);

        vm.prank(jimmy);
        asset.approve(address(newVault), 1 ether);

        vm.prank(hazel);
        newVault.deposit(1 ether, jimmy);

        assertEq(newVault.balanceOf(hazel), 0, "Hazel balance in vault");
        assertEq(newVault.balanceOf(jimmy), 1 ether * 1e9, "Jimmy balance in vault"); // Allow for decimal offset
        assertEq(asset.balanceOf(hazel), 0, "Hazel asset balance");

        vm.prank(jimmy);
        newVault.mint(1e27, hazel);
        assertEq(newVault.balanceOf(hazel), 1e27, "Hazel balance in vault");
        assertEq(newVault.balanceOf(jimmy), 1 ether * 1e9, "Jimmy balance in vault");
        assertEq(asset.balanceOf(jimmy), 0, "Jimmy asset balance");

        vm.prank(hazel);
        newVault.redeem(1e27, jimmy, hazel);

        assertEq(newVault.balanceOf(hazel), 0, "Hazel Vault In Balance");
        assertEq(newVault.balanceOf(jimmy), 1 ether * 1e9, "Jimmy Vault In Balance");
        assertEq(asset.balanceOf(jimmy), 1 ether, "Jimmy Asset Balance");

        vm.prank(jimmy);
        newVault.withdraw(1 ether, hazel, jimmy);
        assertEq(newVault.balanceOf(hazel), 0, "Hazel balance in vault");
        assertEq(newVault.balanceOf(jimmy), 0, "Jimmy balance in vault");
        assertEq(asset.balanceOf(hazel), 1 ether, "Hazel asset balance");
    }

    function test_pausability() public {
        vm.expectEmit();
        emit Paused(admin);
        vm.prank(admin);
        vault.pause();

        assertEq(vault.paused(), true, "Vault should be paused");
        assertEq(vault.maxMint(hazel), 0, "Max mint should be 0");

        vm.expectRevert();
        vm.prank(hazel);
        vault.deposit(1 ether, hazel);

        vm.expectEmit();
        emit Unpaused(admin);
        vm.prank(admin);
        vault.unpause();

        assertEq(vault.paused(), false, "Vault should not be paused");

        vm.expectRevert();
        vm.prank(hazel);
        vault.deposit(1 ether, hazel);
    }

    function test_idleVault() public {
        vm.expectEmit();
        emit ToggleVaultIdle(false, true);
        vm.prank(admin);
        vault.toggleVaultIdle();

        assertEq(vault.vaultIdle(), true, "Vault should be in idle");

        vm.expectEmit();
        emit ToggleVaultIdle(true, false);
        vm.prank(admin);
        vault.toggleVaultIdle();

        assertEq(vault.vaultIdle(), false, "Vault should not be in idle");
    }

    function test_doesNotDepositToStrategyWhenIdle(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        vm.prank(admin);
        newVault.toggleVaultIdle();

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");

        vm.expectRevert(Errors.VaultIsIdle.selector);
        vm.prank(admin);
        newVault.pushFundsToStrategies();

        vm.expectRevert(Errors.VaultIsIdle.selector);
        vm.prank(admin);
        newVault.pushFundsIntoSingleStrategy(1);

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");
    }

    function test_pushFundsIntoSingleStrategy(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        vm.prank(admin);
        newVault.toggleVaultIdle();

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");

        vm.prank(admin);
        newVault.toggleVaultIdle();

        vm.prank(admin);
        newVault.pushFundsIntoSingleStrategy(1);

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");
    }

    function testfail_pushFundsIntoSingleStrategyFailsIfNotEnoughAmount(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        vm.prank(admin);
        newVault.toggleVaultIdle();

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);
        vm.prank(admin);
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.InsufficientVaultFunds.selector,
            address(newVault),
            amount_ * 10,
            amount_
        );
        vm.expectRevert(encodedError);
        newVault.pushFundsIntoSingleStrategy(1, amount_ * 10);
    }

    function test_pushFundsIntoAllStrategies(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        vm.prank(admin);
        newVault.toggleVaultIdle();

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");

        vm.prank(admin);
        newVault.toggleVaultIdle();

        vm.prank(admin);
        newVault.pushFundsToStrategies();

        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );
    }

    function test_pullFundsFromAllStrategies(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );

        vm.prank(admin);
        newVault.pullFundsFromStrategies();

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");
        assertEq(MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)), 0, "Strategy 2 balance");

        assertEq(asset.balanceOf(address(newVault)), amount_, "Vault balance should be equal to amount");
    }

    function test_pullFundsFromAllStrategiesWithLockedFunds(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        Strategy memory protectStrategy = Strategy({
            strategy: IStrategy(address(new MockERC4626Protect(IERC20(address(asset)), "Mock Shares", "MS"))),
            allocation: Allocation({index: 0, amount: 3333})
        });
        vm.prank(admin);
        newVault.addStrategy(2, true, protectStrategy);
        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(protectStrategy.strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );

        //set funds to be locked
        vm.prank(admin);
        uint256 protectStratBalance = asset.balanceOf(address(protectStrategy.strategy));
        uint256 lockedAmount = protectStratBalance / 2;
        MockERC4626Protect(address(protectStrategy.strategy)).lendFunds(lockedAmount);
        vm.prank(admin);
        newVault.pullFundsFromStrategies();

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)), 0, "Strategy 1 balance");

        assertEq(
            MockERC4626Protect(address(protectStrategy.strategy)).totalAssets(),
            protectStratBalance - lockedAmount,
            "Strategy 2 balance"
        );

        assertEq(
            asset.balanceOf(address(newVault)),
            amount_ - lockedAmount,
            "Vault balance should be equal to amount less the lockedamount"
        );
    }

    function test_pullFundsFromSingleStrategy(uint256 amount_) public {
        //uint256 amount_ = 1e18;
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );

        vm.prank(admin);
        newVault.pullFundsFromSingleStrategy(0);

        assertEq(MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)), 0, "Strategy 0 balance");
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );
    }

    function test_pullFundsFromSingleStrategyWithLockedAmount(uint256 amount_) public {
        //uint256 amount_ = 1e18;
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        Strategy memory protectStrategy = Strategy({
            strategy: IStrategy(address(new MockERC4626Protect(IERC20(address(asset)), "Mock Shares", "MS"))),
            allocation: Allocation({index: 0, amount: 3333})
        });
        vm.prank(admin);
        newVault.addStrategy(0, true, protectStrategy);

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        assertEq(
            MockERC4626(address(protectStrategy.strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(3333, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );

        //set funds to be locked
        vm.prank(admin);
        uint256 protectStratBalance = asset.balanceOf(address(protectStrategy.strategy));
        uint256 lockedAmount = protectStratBalance / 2;
        MockERC4626Protect(address(protectStrategy.strategy)).lendFunds(lockedAmount);

        vm.prank(admin);
        newVault.pullFundsFromSingleStrategy(0);

        assertEq(
            MockERC4626Protect(address(protectStrategy.strategy)).totalAssets(),
            protectStratBalance - lockedAmount,
            "Strategy 0 balance"
        );

        assertEq(
            asset.balanceOf(address(newVault)),
            amount_ - protectStratBalance * 3 + protectStratBalance / 2,
            "Vault balance should be equal to amount less the lockedamount"
        );
    }

    function test_addStrategy(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, true, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");

        vm.startPrank(admin);
        newVault.addStrategy(3, false, _createMockStrategy(IERC20(address(asset)), true));
        assertEq(
            MockERC4626(address(newVault.getStrategies()[3].strategy)).balanceOf(address(newVault)),
            0,
            "Strategy 4 balance"
        );

        newVault.pushFundsIntoSingleStrategy(3, amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil));
        assertEq(
            MockERC4626(address(strats[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626(address(strats[1].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626(address(strats[2].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 2 balance"
        );
        assertEq(
            MockERC4626(address(newVault.getStrategies()[3].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "Strategy 4 balance"
        );
        vm.stopPrank();

        // Vault should have balance of 60% of original amount. 100% - 40% to strategies
        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(6000, 10_000, Math.Rounding.Ceil),
            "Vault balance should be equal to amount"
        );
    }

    function testfail_addDuplicatedProtectStrategy() public {
        address vaultAddress = Clones.clone(implementation);

        ConcreteMultiStrategyVault v = ConcreteMultiStrategyVault(vaultAddress);
        Strategy[] memory newStrategy = new Strategy[](2);
        newStrategy[0] = _createMockStrategy(IERC20(address(asset)), false);
        newStrategy[1] = _createMockProstotectStrategy(IERC20(address(asset)), false);
        v.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            newStrategy,
            feeRecipient,
            VaultFees({depositFee: 500, withdrawalFee: 100, protocolFee: 300, performanceFee: graduatedFees}),
            type(uint256).max,
            admin
        );
        bytes memory encodedError = abi.encodeWithSelector(Errors.MultipleProtectStrat.selector);
        Strategy memory strat = _createMockProstotectStrategy(IERC20(address(asset)), true);

        vm.startPrank(admin);
        vm.expectRevert(encodedError);
        v.addStrategy(2, false, strat);
    }

    function test_replaceStrategy(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, true, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");

        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(7000, 10_000, Math.Rounding.Ceil),
            "Vault balance should be equal to amount"
        );

        Strategy memory newMockStrat = _createMockStrategy(IERC20(address(asset)), true);
        address newMockStratAddress = address(newMockStrat.strategy);
        vm.startPrank(admin);
        newVault.addStrategy(0, true, newMockStrat);
        // Check that the balance increased when old strategy was removed
        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(8000, 10_000, Math.Rounding.Ceil),
            "Vault balance should be equal to amount"
        );
        assertEq(
            address(newVault.getStrategies()[0].strategy),
            newMockStratAddress,
            "Strategy 0 should be the new one"
        );

        newVault.pushFundsIntoSingleStrategy(0, amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil));
        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(7000, 10_000, Math.Rounding.Ceil),
            "Vault balance should equal 70% of original amount"
        );
        assertEq(
            MockERC4626(address(newVault.getStrategies()[0].strategy)).balanceOf(address(newVault)),
            amount_.mulDiv(1000, 10_000, Math.Rounding.Ceil) * 1e9,
            "New Strategy Balance"
        );
        vm.stopPrank();
    }

    function test_removeStrategy(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, true, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");

        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(7000, 10_000, Math.Rounding.Ceil),
            "Vault balance should be equal to amount"
        );

        vm.startPrank(admin);

        Strategy[] memory stratsBefore = newVault.getStrategies();
        newVault.removeStrategy(0);
        Strategy[] memory stratsAfter = newVault.getStrategies();
        // Check that the balance increased when old strategy was removed
        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(8000, 10_000, Math.Rounding.Ceil),
            "Vault balance should be equal to amount"
        );
        assertEq(stratsAfter.length, stratsBefore.length - 1, "Strategies array length");
        assertEq(address(stratsAfter[0].strategy), address(stratsBefore[2].strategy), "Strategy 1");
        assertEq(address(stratsAfter[1].strategy), address(stratsBefore[1].strategy), "Strategy 2");
        vm.stopPrank();
    }

    function testfail_removeNonExistentStrategy(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, true, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");

        assertEq(
            asset.balanceOf(address(newVault)),
            amount_.mulDiv(7000, 10_000, Math.Rounding.Ceil),
            "Vault balance should be equal to amount"
        );

        vm.startPrank(admin);
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidIndex.selector, 3);
        vm.expectRevert(encodedError);
        newVault.removeStrategy(3);

        vm.stopPrank();
    }

    function testfail_replacingProtectStrategyWithDebt() public {
        uint256 amount_ = 1e18;
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        MockERC4626Protect protectStrategy = new MockERC4626Protect(
            IERC20(address(asset)),
            "Mock Protect Shares",
            "MS"
        );
        Strategy memory newStrategy = Strategy({
            strategy: IStrategy(address(protectStrategy)),
            allocation: Allocation({index: 0, amount: 3333})
        });

        vm.prank(admin);
        newVault.addStrategy(2, true, newStrategy);

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");
        protectStrategy.lendFunds(asset.balanceOf(address(protectStrategy)) / 6);

        Strategy memory anotherStrategy = Strategy({
            strategy: IStrategy(address(new MockERC4626(IERC20(address(asset)), "Mock Shares", "MS"))),
            allocation: Allocation({index: 0, amount: 3333})
        });

        vm.prank(admin);
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.StrategyHasLockedAssets.selector,
            address(protectStrategy)
        );
        vm.expectRevert(encodedError);
        newVault.addStrategy(2, true, anotherStrategy);
    }

    function test_addReplaceStrategyAllotmentTooHigh() public {
        uint256 amount_ = 1e18;
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelShares, amount_ * 1e9, "Shares with Offset");

        Strategy memory invalidStrategy = Strategy({
            strategy: IStrategy(address(new MockERC4626(IERC20(address(asset)), "Mock Shares", "MS"))),
            allocation: Allocation({index: 0, amount: 5000})
        });

        vm.expectRevert(Errors.AllotmentTotalTooHigh.selector);
        vm.startPrank(admin);
        newVault.addStrategy(3, false, invalidStrategy);

        vm.expectRevert(Errors.AllotmentTotalTooHigh.selector);
        newVault.addStrategy(0, true, invalidStrategy);
        vm.stopPrank();
    }

    function test_setDepositLimit() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        assertEq(newVault.depositLimit(), type(uint256).max, "Deposit limit should be max");

        vm.prank(admin);
        newVault.setDepositLimit(1e18);
        assertEq(newVault.depositLimit(), 1e18, "Deposit limit should be 1e18");
    }

    function test_shouldNotLetUserViolateDepositLimit() public {
        uint256 amount_ = 4 ether;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        vm.prank(admin);
        newVault.setDepositLimit(1e18);

        asset.mint(hazel, amount_);
        vm.prank(hazel);
        asset.approve(address(newVault), amount_);

        vm.expectRevert(Errors.MaxError.selector);
        vm.prank(hazel);
        newVault.deposit(amount_, hazel);
    }

    function test_changeFees() public {
        vm.prank(admin);
        vault.setVaultFees(VaultFees({depositFee: 10, withdrawalFee: 10, protocolFee: 10, performanceFee: zeroFees}));

        VaultFees memory fee_ = vault.getVaultFees();

        assertEq(fee_.depositFee, 10, "Deposit fee should be 10");
        assertEq(fee_.withdrawalFee, 10, "Withdrawal fee should be 10");
        assertEq(fee_.protocolFee, 10, "Protocol fee should be 10");
        assertEq(fee_.performanceFee.length, 1, "Performance fee length should be 1");
    }

    function testFail_changeFees() public {
        vm.prank(jimmy);
        vault.setVaultFees(
            VaultFees({depositFee: 10, withdrawalFee: 10, protocolFee: 10, performanceFee: graduatedFees})
        );
    }

    function test_changeFeeRecipient() public {
        vm.expectEmit();
        emit FeeRecipientUpdated(feeRecipient, hazel);
        vm.prank(admin);
        vault.setFeeRecipient(hazel);

        assertEq(vault.feeRecipient(), hazel, "Fee recipient should be hazel");
    }

    function testFail_changeFeeRecipientZeroAddress() public {
        vm.prank(hazel);
        vault.setFeeRecipient(address(0));
    }

    // ============= FEES ==============================
    function test_previewDepositAccountsForFees() public {
        uint256 jimmysAmount = 7 ether;
        uint256 afterDepositExpectedAssets = 0.07 ether;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(true, false, false);

        asset.mint(jimmy, jimmysAmount);

        vm.startPrank(jimmy);
        asset.approve(address(newVault), jimmysAmount);
        newVault.deposit(jimmysAmount, jimmy);
        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);

        uint256 expectedFeeInShares = newVault.balanceOf(feeRecipient);
        vm.prank(feeRecipient);
        uint256 expectedFeeInAssets = newVault.previewRedeem(expectedFeeInShares);
        assertEq(expectedFeeInShares / 1e9, afterDepositExpectedAssets, "Fee should be 0.07 ether");
        assertEq(expectedFeeInAssets, 0.07 ether, "Fee in assets should be 0.07 ether");

        vm.prank(feeRecipient);
        newVault.withdraw(expectedFeeInAssets, feeRecipient, feeRecipient);

        assertEq(asset.balanceOf(feeRecipient), 0.07 ether, "Fee recipient should have 0.07 ether");
    }

    function test_withdrawalFees() public {
        vm.prank(admin);
        vault.setVaultFees(VaultFees({depositFee: 0, withdrawalFee: 1000, protocolFee: 0, performanceFee: zeroFees})); //10%

        uint256 depositAmount = 1 ether;
        asset.mint(jimmy, depositAmount);
        asset.mint(hazel, depositAmount);

        vm.startPrank(hazel);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, hazel);
        vm.stopPrank();

        vm.startPrank(jimmy);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 withdrawAmount = (depositAmount / 10) * 9;
        uint256 expectedShares = vault.previewWithdraw(withdrawAmount);
        vm.prank(hazel);
        uint256 actualShares = vault.withdraw(withdrawAmount);

        assertApproxEqAbs(expectedShares, actualShares, 1, "Shares");

        assertEq(vault.balanceOf(feeRecipient), expectedShares.mulDiv(1000, 10_000, Math.Rounding.Floor));

        uint256 expectedAssets = vault.previewRedeem(shares);

        vm.prank(jimmy);
        uint256 actualAssets = vault.redeem(shares, jimmy, jimmy);
        assertApproxEqAbs(expectedAssets, actualAssets, 1, "Assets");
    }

    function test_protocolFee(uint128 timeframe) public {
        timeframe = uint128(bound(timeframe, 1, 315576000));
        vm.prank(admin);
        vault.setVaultFees(VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 500, performanceFee: zeroFees}));
        uint256 depositAmount = 1 ether;
        asset.mint(jimmy, depositAmount * 2);

        vm.startPrank(jimmy);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(depositAmount, jimmy);
        vm.stopPrank();

        vm.warp(block.timestamp + timeframe);

        uint256 feeInAsset = vault.accruedProtocolFee();

        uint256 supply = vault.totalSupply();
        uint256 expectedFeeInShares = supply == 0 ? feeInAsset : feeInAsset.mulDiv(supply, 1 ether - feeInAsset);

        vault.takePortfolioAndProtocolFees();
        uint256 recipientShares = vault.balanceOf(feeRecipient);
        uint256 expectedFeeInAsset = vault.previewRedeem(recipientShares);
        assertEq(vault.totalSupply(), (depositAmount * 1e9) + expectedFeeInShares, "Total Supply");
        assertEq(vault.balanceOf(feeRecipient), expectedFeeInShares, "Fee recipient balance");
        assertApproxEqAbs(vault.convertToAssets(expectedFeeInShares), expectedFeeInAsset, 10, "Converted to assets");
    }

    function test_protocolFeeWithFeeChange() public {
        vm.prank(admin);
        vault.setVaultFees(VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: zeroFees}));
        uint256 depositAmount = 1 ether;

        asset.mint(jimmy, depositAmount);
        vm.startPrank(jimmy);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, jimmy);
        vm.stopPrank();

        // Set it to half the time without any fees
        vm.warp(block.timestamp + (365.25 days / 2));
        assertEq(vault.accruedProtocolFee(), 0, "accrued protocol fee");

        vm.prank(admin);
        vault.setVaultFees(VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 5000, performanceFee: zeroFees}));

        uint256 newTimestamp = block.timestamp + (365.25 days / 2);
        // workaround to handle vm.warp issue when compiling via --via-ir
        // https://github.com/foundry-rs/foundry/issues/1373
        // Note: accured rewards will be more than expected since we have added extra block
        vm.warp(newTimestamp + 1);
        assertApproxEqAbs(
            vault.accruedProtocolFee(),
            ((depositAmount.mulDiv(5000, 10000, Math.Rounding.Ceil)) / 2),
            20000000000,
            "accrued protocol fee2"
        );
    }

    function test_performanceFee() public {
        uint128 amount = 1 ether;
        uint256 depositAmount = 1 ether;

        vm.prank(admin);
        vault.setVaultFees(VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: graduatedFees}));

        asset.mint(hazel, depositAmount);
        vm.startPrank(hazel);
        asset.approve(address(vault), amount);
        uint256 shares = vault.deposit(depositAmount, hazel);
        vm.stopPrank();
        assertEq(vault.balanceOf(hazel), shares, "Balance of hazel should equal shares");

        asset.mint(address(strategies[0].strategy), amount);

        uint256 supply = vault.totalSupply();
        uint256 totalAssets = vault.totalAssets();
        uint256 expectedFeeInAsset = vault.accruedPerformanceFee();
        uint256 expectedFeeInShares = supply == 0
            ? expectedFeeInAsset
            : expectedFeeInAsset.mulDiv(supply, totalAssets - expectedFeeInAsset);
        vault.takePortfolioAndProtocolFees();

        assertEq(vault.totalSupply(), (depositAmount * 1e9) + expectedFeeInShares, "Total Supply");
        assertEq(vault.balanceOf(feeRecipient), expectedFeeInShares, "Fee recipient balance");
        assertApproxEqAbs(vault.convertToAssets(expectedFeeInShares), expectedFeeInAsset, 10, "Converted to assets");
        assertApproxEqRel(vault.highWaterMark(), totalAssets / 1e9, 20, "High water mark");
    }
    //We may add the functionality soon
    // function test_permit() public {
    //     uint256 privateKey = 0xEEEE;
    //     address owner = vm.addr(privateKey);

    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(
    //         privateKey,
    //         keccak256(
    //             abi.encodePacked(
    //                 "\x19\x01",
    //                 vault.DOMAIN_SEPARATOR(),
    //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
    //             )
    //         )
    //     );

    //     vault.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

    //     assertEq(vault.allowance(owner, address(0xCAFE)), 1e18);
    //     assertEq(vault.nonces(owner), 1);
    // }

    //Queue

    function test_deposit_withdraw_request_withdrawal(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000_000);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e9;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, true);

        //TODO add the withdrawQueue
        WithdrawalQueue queue = new WithdrawalQueue(address(newVault));
        vm.prank(admin);
        newVault.setWithdrawalQueue(address(queue));
        //--
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);
        assertEq(hazelsAmount * 1e9, hazelShares, "Shares with Offset");
        assertEq(preDepositBalance - amount_, asset.balanceOf(hazel), "Pre-deposit balance");
        assertEq(newVault.balanceOf(hazel), hazelShares, "Hazels balance in vault");
        assertEq(newVault.totalAssets(), hazelsAmount, "Total assets");
        assertEq(newVault.totalSupply(), hazelShares, "Total supply");
        assertEq(newVault.previewDeposit(hazelsAmount), hazelShares, "Preview deposit");
        assertEq(newVault.previewWithdraw(hazelsAmount), hazelShares, "Preview withdraw");
        assertEq(newVault.convertToAssets(newVault.balanceOf(hazel)), hazelsAmount);
        assertEq(asset.balanceOf(hazel), 0, "Hazels asset balance after deposit");

        assertEq(
            MockERC4626Queue(address(strats[0].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[0].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626Queue(address(strats[1].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[1].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626Queue(address(strats[2].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[2].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 2 balance"
        );

        assertEq(queue.getLastRequestId(), 0, "Last request");

        vm.prank(hazel);
        newVault.withdraw(hazelsAmount, hazel, hazel);
        vm.stopPrank();

        assertEq(queue.getLastRequestId(), 1, "Last request");

        uint256[] memory singleElementArray = new uint256[](1);
        singleElementArray[0] = uint256(1);

        WithdrawalQueue.WithdrawalRequestStatus[] memory request = queue.getWithdrawalStatus(singleElementArray);
        assertEq(request[0].recipient, hazel, "Recipient");
        assertEq(request[0].isClaimed, false, "Is claimed");
        assertEq(request[0].amount, amount_, "Amount");

        assertEq(asset.balanceOf(hazel), 0, "Hazels asset Balance");
        assertEq(newVault.balanceOf(hazel), 0, "Hazels balance in vault");
        assertEq(newVault.totalAssets(), 0, "Total assets");
        assertEq(newVault.totalSupply(), 0, "Total supply");

        assertEq(
            MockERC4626Queue(address(strats[0].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[0].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 0 balance"
        );
        assertEq(
            MockERC4626Queue(address(strats[1].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[1].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 1 balance"
        );
        assertEq(
            MockERC4626Queue(address(strats[2].strategy)).balanceOf(address(newVault)),
            hazelShares.mulDiv(strats[2].allocation.amount, 10000, Math.Rounding.Floor),
            "Strategy 2 balance"
        );
    }

    function test_deposit_withdraw_request_withdrawal_with_fee(
        uint256 amount_,
        uint64 depositFee,
        uint64 withdrawalFee
    ) public {
        vm.assume(amount_ <= 100_000_000_000);
        vm.assume(amount_ > 0);
        vm.assume(depositFee < 5000);
        vm.assume(withdrawalFee < 5000);
        amount_ = amount_ * 1e9;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(true, false, true);

        WithdrawalQueue queue = new WithdrawalQueue(address(newVault));
        vm.prank(admin);
        newVault.setWithdrawalQueue(address(queue));

        vm.prank(admin);
        newVault.setVaultFees(
            VaultFees({depositFee: depositFee, withdrawalFee: withdrawalFee, protocolFee: 0, performanceFee: zeroFees})
        );
        vm.stopPrank();
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        uint256 netAmount = hazelsAmount;
        if (depositFee != 0) netAmount -= hazelsAmount.mulDiv(uint256(depositFee), 10_000, Math.Rounding.Floor);

        uint256 rest = hazelsAmount.mulDiv(depositFee, 10_000, Math.Rounding.Floor) +
            netAmount.mulDiv(withdrawalFee, 10_000, Math.Rounding.Floor);

        if (withdrawalFee != 0) netAmount -= netAmount.mulDiv(uint256(withdrawalFee), 10_000, Math.Rounding.Floor);
        uint256 expected = newVault.previewWithdraw(netAmount);

        vm.prank(hazel);
        uint256 result = newVault.withdraw(netAmount, hazel, hazel);

        assertEq(expected, result, "Preview withdraw");
        assertEq(queue.getLastRequestId(), 1, "Last request");

        uint256[] memory singleElementArray = new uint256[](1);
        singleElementArray[0] = uint256(1);

        WithdrawalQueue.WithdrawalRequestStatus[] memory request = queue.getWithdrawalStatus(singleElementArray);
        assertEq(request[0].recipient, hazel, "Recipient");
        assertEq(request[0].isClaimed, false, "Is claimed");
        assertEq(request[0].amount, netAmount, "Amount");

        assertEq(asset.balanceOf(hazel), 0, "Hazels asset Balance");
        assertEq(newVault.balanceOf(hazel), 0, "Hazels balance in vault");

        assertEq(newVault.totalAssets(), rest, "Total assets");
        assertEq(newVault.totalSupply(), newVault.convertToShares(rest), "Total supply");
    }

    function test_mint_redeem_request_withdrawal_with_fee(
        uint256 amount_,
        uint64 depositFee,
        uint64 withdrawalFee
    ) public {
        vm.assume(amount_ <= 100_000_000_000);
        vm.assume(amount_ > 0);
        vm.assume(depositFee < 5000);
        vm.assume(withdrawalFee < 5000);
        amount_ = amount_ * 1e9;

        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(true, false, true);
        //TODO add the withdrawQueue
        WithdrawalQueue queue = new WithdrawalQueue(address(newVault));
        vm.prank(admin);
        newVault.setWithdrawalQueue(address(queue));
        assertEq(address(newVault.withdrawalQueue()), address(queue), "Withdrawal queue");
        //--
        vm.prank(admin);
        newVault.setVaultFees(
            VaultFees({depositFee: depositFee, withdrawalFee: withdrawalFee, protocolFee: 0, performanceFee: zeroFees})
        );
        vm.stopPrank();
        uint256 hazelsAmount = amount_;
        uint256 hazelsShares = amount_ * 1e9;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        assertEq(asset.balanceOf(hazel), amount_, "Predeposit balance == amount");

        uint256 netShares = hazelsShares;
        if (depositFee != 0) netShares -= hazelsShares.mulDiv(uint256(depositFee), 10_000, Math.Rounding.Floor);
        uint256 previewAmount = newVault.previewMint(netShares);

        vm.prank(hazel);
        // uint256 returnedAmount = ;

        assertEq(previewAmount, newVault.mint(netShares, hazel), "previewAmonut");

        uint256 previewRedeem = newVault.previewRedeem(netShares);
        vm.prank(hazel);
        uint256 result = newVault.redeem(netShares, hazel, hazel);

        assertEq(previewRedeem, result, "Preview withdraw");
        assertEq(queue.getLastRequestId(), 1, "Last request");

        uint256[] memory singleElementArray = new uint256[](1);
        singleElementArray[0] = uint256(1);

        WithdrawalQueue.WithdrawalRequestStatus[] memory request = queue.getWithdrawalStatus(singleElementArray);
        assertEq(request[0].recipient, hazel, "Recipient");
        assertEq(request[0].isClaimed, false, "Is claimed");
        assertEq(request[0].amount, result, "Amount");
        assertEq(asset.balanceOf(hazel), 0, "Hazels asset Balance");
        assertEq(newVault.balanceOf(hazel), 0, "Hazels balance in vault");

        uint256 netAmount = hazelsAmount;
        if (depositFee != 0) netAmount -= hazelsAmount.mulDiv(uint256(depositFee), 10_000, Math.Rounding.Floor);

        uint256 rest = hazelsAmount.mulDiv(depositFee, 10_000, Math.Rounding.Floor) +
            netAmount.mulDiv(withdrawalFee, 10_000, Math.Rounding.Floor);

        assertEq(newVault.totalAssets(), rest, "Total assets");
        assertEq(newVault.totalSupply(), newVault.convertToShares(rest), "Total supply");
    }

    function test_claimRequests() public {
        (ConcreteMultiStrategyVault newVault, , , , WithdrawalQueue queue) = createQueue(1 ether);

        assertEq(queue.getLastRequestId(), 4, "Last request");
        assertEq(queue.getLastFinalizedRequestId(), 0, "Last finalized request");
        uint256[] memory requests = queue.getWithdrawalRequests(ellie);
        assertEq(requests.length, 2, "Last request");

        uint256 hazelBalanceBefore = asset.balanceOf(hazel);
        uint256 jimmyBalanceBefore = asset.balanceOf(jimmy);
        uint256 ellieBalanceBefore = asset.balanceOf(ellie);

        uint256 totalAssetsBefore = newVault.totalAssets();
        uint256 max = 999;
        vm.prank(admin);
        newVault.batchClaimWithdrawal(max);
        assertEq(queue.getLastFinalizedRequestId(), 4, "Last finalized request");

        uint256 hazelBalanceAfter = asset.balanceOf(hazel);
        uint256 jimmyBalanceAfter = asset.balanceOf(jimmy);
        uint256 ellieBalanceAfter = asset.balanceOf(ellie);

        uint256 totalAssetsAfter = newVault.totalAssets();

        assertEq(totalAssetsAfter, totalAssetsBefore, "totalAssets");

        assertGt(hazelBalanceAfter, hazelBalanceBefore, "Hazel balance after");
        assertGt(jimmyBalanceAfter, jimmyBalanceBefore, "Jimmy balance after");
        assertGt(ellieBalanceAfter, ellieBalanceBefore, "Ellie balance after");
    }

    function testfail_setwithdrawlQueue() public {
        (ConcreteMultiStrategyVault newVault, , , , WithdrawalQueue queue) = createQueue(1 ether);
        WithdrawalQueue newQueue = new WithdrawalQueue(address(newVault));
        bytes memory encodedError = abi.encodeWithSelector(Errors.UnfinalizedWithdrawl.selector, address(queue));
        vm.expectRevert(encodedError);
        vm.prank(admin);
        newVault.setWithdrawalQueue(address(newQueue));
    }

    function testfail_createRequestIfThereIsNoQueue() public {
        uint256 amount_ = 1e20;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, true);

        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        bytes memory encodedError = abi.encodeWithSelector(
            Errors.InsufficientVaultFunds.selector,
            newVault,
            100000000000000000000,
            10000000000000000
        );
        vm.expectRevert(encodedError);
        vm.prank(hazel);
        newVault.withdraw(hazelsAmount, hazel, hazel);
        vm.stopPrank();
    }

    function testfail_batchClaimIfThereIsNoQueue() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, true);

        bytes memory encodedError = abi.encodeWithSelector(Errors.QueueNotSet.selector);
        vm.expectRevert(encodedError);
        vm.prank(admin);
        newVault.batchClaimWithdrawal(1);
    }
    //-----

    function test_changeAllocations() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);

        Allocation[] memory allocations = new Allocation[](3);
        allocations[0] = Allocation({index: 0, amount: 2500});
        allocations[1] = Allocation({index: 0, amount: 2500});
        allocations[2] = Allocation({index: 0, amount: 5000});
        vm.prank(admin);
        newVault.changeAllocations(allocations, false);

        Strategy[] memory newStrategies = newVault.getStrategies();

        assertEq(newStrategies[0].allocation.amount, 2500, "Strategy 1");
        assertEq(newStrategies[0].allocation.index, 0, "Strategy 1");
        assertEq(newStrategies[1].allocation.amount, 2500, "Strategy 2");
        assertEq(newStrategies[1].allocation.index, 0, "Strategy 2");
        assertEq(newStrategies[2].allocation.amount, 5000, "Strategy 3");
        assertEq(newStrategies[2].allocation.index, 0, "Strategy 3");
    }

    function test_changeAllocationsAndRelocateFunds(uint256 amount_) public {
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsAmount);

        uint256 preDepositBalance = asset.balanceOf(hazel);
        assertEq(preDepositBalance, amount_, "Predeposit balance == amount");

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        Allocation[] memory allocations = new Allocation[](3);
        allocations[0] = Allocation({index: 0, amount: 2500});
        allocations[1] = Allocation({index: 0, amount: 2500});
        allocations[2] = Allocation({index: 0, amount: 5000});
        vm.prank(admin);
        newVault.changeAllocations(allocations, true);

        Strategy[] memory newStrategies = newVault.getStrategies();

        assertEq(
            asset.balanceOf(address(newStrategies[0].strategy)),
            hazelsAmount.mulDiv(2500, 10000, Math.Rounding.Floor),
            "Strategy 1"
        );

        assertEq(
            asset.balanceOf(address(newStrategies[1].strategy)),
            hazelsAmount.mulDiv(2500, 10000, Math.Rounding.Floor),
            "Strategy 2"
        );

        assertEq(
            asset.balanceOf(address(newStrategies[2].strategy)),
            hazelsAmount.mulDiv(5000, 10000, Math.Rounding.Floor),
            "Strategy 3"
        );
    }

    function testfail_changeAllocationsWrongfAllocationLength() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);

        Allocation[] memory allocations = new Allocation[](4);
        allocations[0] = Allocation({index: 0, amount: 2500});
        allocations[1] = Allocation({index: 0, amount: 1500});
        allocations[2] = Allocation({index: 0, amount: 5000});
        allocations[3] = Allocation({index: 0, amount: 1000});
        vm.prank(admin);

        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidLength.selector, 4, 3);
        vm.expectRevert(encodedError);
        newVault.changeAllocations(allocations, false);
    }

    function testfail_changeAllocationsWrongTotalAllotment() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, false, false);

        Allocation[] memory allocations = new Allocation[](3);
        allocations[0] = Allocation({index: 0, amount: 2500});
        allocations[1] = Allocation({index: 0, amount: 3500});
        allocations[2] = Allocation({index: 0, amount: 5000});
        vm.prank(admin);

        bytes memory encodedError = abi.encodeWithSelector(Errors.AllotmentTotalTooHigh.selector);
        vm.expectRevert(encodedError);
        newVault.changeAllocations(allocations, false);
    }

    // ============= REWARDS =========================

    function test_harvestRewards() public {
        uint256 amount_ = 10000 * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, true, false);

        MockERC20 rewardStrat1 = new MockERC20("Reward1", "R1", 6);
        MockERC20 rewardStrat2 = new MockERC20("Reward2", "R2", 6);
        MockERC4626(address(strats[0].strategy)).setRewardPrep(address(newVault), address(rewardStrat1), address(0));
        MockERC4626(address(strats[1].strategy)).setRewardPrep(address(newVault), address(rewardStrat2), address(0));
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, 2 * hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), 2 * hazelsAmount);

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        address[] memory rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 0, "Reward tokens length 0");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 0, "Reward 1 balance 0");
        assertEq(rewardStrat2.balanceOf(address(newVault)), 0, "Reward 2 balance 0");
        assertEq(newVault.rewardIndex(address(rewardStrat1)), 0, "Reward 1 index 0");
        assertEq(newVault.rewardIndex(address(rewardStrat2)), 0, "Reward 1 index 0");

        vm.prank(admin);
        newVault.harvestRewards("");

        uint256 rewardIndex1 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);
        uint256 rewardIndex2 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);
        rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 2, "Reward tokens length 2");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 10000000, "Reward 1 balance");
        assertEq(rewardStrat2.balanceOf(address(newVault)), 10000000, "Reward 2 balance");
        assertEq(newVault.rewardIndex(address(rewardStrat1)), rewardIndex1, "Reward 1 index");
        assertEq(newVault.rewardIndex(address(rewardStrat2)), rewardIndex2, "Reward 2 index");

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        uint256 userRewardIndex1 = newVault.userRewardIndex(hazel, address(rewardStrat1));
        uint256 userRewardIndex2 = newVault.userRewardIndex(hazel, address(rewardStrat2));
        assertEq(userRewardIndex1, rewardIndex1, "User reward 1 index");
        assertEq(userRewardIndex2, rewardIndex2, "User reward 2 index");

        vm.prank(admin);
        newVault.harvestRewards("");

        rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 2, "Reward tokens length 2");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 10000000, "Reward 1 balance");
        assertEq(rewardStrat2.balanceOf(address(newVault)), 10000000, "Reward 2 balance");
        assertEq(
            newVault.rewardIndex(address(rewardStrat1)),
            rewardIndex1 + PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor),
            "Reward 1 index"
        );
        assertEq(
            newVault.rewardIndex(address(rewardStrat2)),
            rewardIndex2 + PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor),
            "Reward 2 index"
        );

        vm.prank(hazel);
        newVault.claimRewards();
        assertEq(
            newVault.totalRewardsClaimed(hazel, address(rewardStrat1)),
            rewardStrat1.balanceOf(hazel),
            "Total rewards claimed"
        );
        assertEq(
            newVault.totalRewardsClaimed(hazel, address(rewardStrat2)),
            rewardStrat2.balanceOf(hazel),
            "Total rewards claimed"
        );

        ReturnedRewards[] memory claimedRewards = newVault.getTotalRewardsClaimed(address(hazel));
        assertEq(claimedRewards[0].rewardAmount, rewardStrat1.balanceOf(hazel), "Hazel reward 1 address");
        assertEq(claimedRewards[1].rewardAmount, rewardStrat2.balanceOf(hazel), "Hazel reward 2 address");
    }

    function test_harvestRewardsTwoStratsWithTheSameRewardToken() public {
        uint256 amount_ = 10000 * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, true, false);

        MockERC20 rewardStrat1 = new MockERC20("Reward1", "R1", 6);
        MockERC4626(address(strats[0].strategy)).setRewardPrep(address(newVault), address(rewardStrat1), address(0));
        MockERC4626(address(strats[1].strategy)).setRewardPrep(address(newVault), address(rewardStrat1), address(0));
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, 2 * hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), 2 * hazelsAmount);

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        address[] memory rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 0, "Reward tokens length 0");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 0, "Reward 1 balance 0");
        assertEq(newVault.rewardIndex(address(rewardStrat1)), 0, "Reward 1 index 0");

        vm.prank(admin);
        newVault.harvestRewards("");

        uint256 rewardIndex1 = PRECISION.mulDiv(20000000, newVault.totalSupply(), Math.Rounding.Floor);
        rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 1, "Reward tokens length 1");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 20000000, "Reward 1 balance");
        assertEq(newVault.rewardIndex(address(rewardStrat1)), rewardIndex1, "Reward 1 index");

        vm.prank(hazel);
        newVault.claimRewards();
        assertEq(rewardStrat1.balanceOf(hazel), 20000000, "Reward 1 balance");
        assertEq(newVault.totalRewardsClaimed(hazel, address(rewardStrat1)), 20000000, "Total rewards claimed");
    }

    function test_harvestRewardsStratsWithMoreThanOneSameRewardToken() public {
        uint256 amount_ = 10000 * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, true, false);

        MockERC20 rewardStrat1 = new MockERC20("Reward1", "R1", 6);
        MockERC20 rewardStrat1b = new MockERC20("Reward1b", "R1b", 6);
        MockERC20 rewardStrat2 = new MockERC20("Reward2", "R2", 6);
        MockERC4626(address(strats[0].strategy)).setRewardPrep(
            address(newVault),
            address(rewardStrat1),
            address(rewardStrat1b)
        );
        MockERC4626(address(strats[1].strategy)).setRewardPrep(address(newVault), address(rewardStrat2), address(0));
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, 2 * hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), 2 * hazelsAmount);

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        address[] memory rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 0, "Reward tokens length 0");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 0, "Reward 1 balance 0");
        assertEq(rewardStrat1b.balanceOf(address(newVault)), 0, "Reward 1b balance 0");
        assertEq(rewardStrat2.balanceOf(address(newVault)), 0, "Reward 2 balance 0");
        assertEq(newVault.rewardIndex(address(rewardStrat1)), 0, "Reward 1 index 0");
        assertEq(newVault.rewardIndex(address(rewardStrat2)), 0, "Reward 1 index 0");

        vm.prank(admin);
        newVault.harvestRewards("");

        uint256 rewardIndex1 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);
        uint256 rewardIndex1b = PRECISION.mulDiv(20000000, newVault.totalSupply(), Math.Rounding.Floor);
        uint256 rewardIndex2 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);
        rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 3, "Reward tokens length 3");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 10000000, "Reward 1 balance");
        assertEq(rewardStrat1b.balanceOf(address(newVault)), 20000000, "Reward 1b balance");
        assertEq(rewardStrat2.balanceOf(address(newVault)), 10000000, "Reward 2 balance");
        assertEq(newVault.rewardIndex(address(rewardStrat1)), rewardIndex1, "Reward 1 index");
        assertEq(newVault.rewardIndex(address(rewardStrat1b)), rewardIndex1b, "Reward 1 index");
        assertEq(newVault.rewardIndex(address(rewardStrat2)), rewardIndex2, "Reward 2 index");

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        vm.prank(admin);
        newVault.harvestRewards("");

        rewardTokens = newVault.getRewardTokens();
        assertEq(rewardTokens.length, 3, "Reward tokens length 3");
        assertEq(rewardStrat1.balanceOf(address(newVault)), 10000000, "Reward 1 balance");
        assertEq(rewardStrat1b.balanceOf(address(newVault)), 20000000, "Reward 1 balance");
        assertEq(rewardStrat2.balanceOf(address(newVault)), 10000000, "Reward 2 balance");
        assertEq(
            newVault.rewardIndex(address(rewardStrat1)),
            rewardIndex1 + PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor),
            "Reward 1 index"
        );
        assertEq(
            newVault.rewardIndex(address(rewardStrat1b)),
            rewardIndex1b + PRECISION.mulDiv(20000000, newVault.totalSupply(), Math.Rounding.Floor),
            "Reward 1b index"
        );
        assertEq(
            newVault.rewardIndex(address(rewardStrat2)),
            rewardIndex2 + PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor),
            "Reward 2 index"
        );

        vm.prank(hazel);
        newVault.claimRewards();
        assertEq(
            newVault.totalRewardsClaimed(hazel, address(rewardStrat1)),
            rewardStrat1.balanceOf(hazel),
            "Total rewards claimed"
        );
        assertEq(
            newVault.totalRewardsClaimed(hazel, address(rewardStrat1b)),
            rewardStrat1b.balanceOf(hazel),
            "Total rewards claimed"
        );
        assertEq(
            newVault.totalRewardsClaimed(hazel, address(rewardStrat2)),
            rewardStrat2.balanceOf(hazel),
            "Total rewards claimed"
        );

        ReturnedRewards[] memory claimedRewards = newVault.getTotalRewardsClaimed(address(hazel));
        assertEq(claimedRewards[0].rewardAmount, rewardStrat1.balanceOf(hazel), "Hazel reward 1 address");
        assertEq(claimedRewards[1].rewardAmount, rewardStrat1b.balanceOf(hazel), "Hazel reward 2 address");
        assertEq(claimedRewards[2].rewardAmount, rewardStrat2.balanceOf(hazel), "Hazel reward 3 address");
    }

    function testFail_harvestRewardsUnauthorized() public {
        (ConcreteMultiStrategyVault newVault, ) = _createNewVault(false, true, false);
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
        newVault.harvestRewards("");
    }

    function test_updateRewardsOnDepositAndWitdrawal() public {
        uint256 amount_ = 10000 * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, true, false);

        MockERC20 rewardStrat1 = new MockERC20("Reward1", "R1", 6);
        MockERC20 rewardStrat1b = new MockERC20("Reward1b", "R1b", 6);
        MockERC20 rewardStrat2 = new MockERC20("Reward2", "R2", 6);
        MockERC4626(address(strats[0].strategy)).setRewardPrep(
            address(newVault),
            address(rewardStrat1),
            address(rewardStrat1b)
        );
        MockERC4626(address(strats[1].strategy)).setRewardPrep(address(newVault), address(rewardStrat2), address(0));
        uint256 hazelsAmount = amount_;
        uint256 jimmysAmount = amount_;
        asset.mint(hazel, 2 * hazelsAmount);
        asset.mint(jimmy, 2 * jimmysAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), 2 * hazelsAmount);

        vm.prank(jimmy);
        asset.approve(address(newVault), 2 * jimmysAmount);

        vm.prank(hazel);
        newVault.deposit(hazelsAmount, hazel);

        assertEq(newVault.userRewardIndex(hazel, address(rewardStrat1)), 0, "User reward 1 index");
        assertEq(newVault.userRewardIndex(hazel, address(rewardStrat2)), 0, "User reward 2 index");

        vm.prank(admin);
        newVault.harvestRewards("");

        uint256 rewardIndex1 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);
        uint256 rewardIndex2 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);
        vm.prank(jimmy);
        newVault.deposit(jimmysAmount, jimmy);

        uint256 jimmyRewardIndex1 = newVault.userRewardIndex(jimmy, address(rewardStrat1));
        uint256 jimmyRewardIndex2 = newVault.userRewardIndex(jimmy, address(rewardStrat2));

        assertEq(jimmyRewardIndex1, rewardIndex1, "Jimmy reward 1 index");
        assertEq(jimmyRewardIndex2, rewardIndex2, "Jimmy reward 2 index");

        vm.prank(admin);
        newVault.harvestRewards("");

        ReturnedRewards[] memory returnedRewards = newVault.getUserRewards(hazel);
        vm.prank(hazel);
        newVault.withdraw(hazelsAmount, hazel, hazel);

        assertEq(returnedRewards[0].rewardAmount, rewardStrat1.balanceOf(address(hazel)), "Hazel reward 1 balance");
        assertEq(returnedRewards[1].rewardAmount, rewardStrat1b.balanceOf(address(hazel)), "Hazel reward 1b balance");
        assertEq(returnedRewards[2].rewardAmount, rewardStrat2.balanceOf(address(hazel)), "Hazel reward 2 balance");

        assertEq(
            newVault.userRewardIndex(hazel, address(rewardStrat1)),
            newVault.rewardIndex(address(rewardStrat1)),
            "Reward indexes"
        );

        vm.prank(jimmy);
        newVault.withdraw(jimmysAmount, jimmy, jimmy);

        assertEq(5000000, rewardStrat1.balanceOf(address(jimmy)), "jimmy reward 1 balance");
        assertEq(10000000, rewardStrat1b.balanceOf(address(jimmy)), "jimmy reward 1b balance");
        assertEq(5000000, rewardStrat2.balanceOf(address(jimmy)), "jimmy reward 2 balance");

        assertEq(newVault.totalRewardsClaimed(jimmy, address(rewardStrat1)), 5000000, "Total rewards claimed");
        assertEq(newVault.totalRewardsClaimed(jimmy, address(rewardStrat1b)), 10000000, "Total rewards claimed");
        assertEq(newVault.totalRewardsClaimed(jimmy, address(rewardStrat2)), 5000000, "Total rewards claimed");

        ReturnedRewards[] memory claimedRewards = newVault.getTotalRewardsClaimed(address(jimmy));
        assertEq(claimedRewards[0].rewardAmount, 5000000, "Hazel reward 1 balance");
        assertEq(claimedRewards[1].rewardAmount, 10000000, "Hazel reward 1b balance");
        assertEq(claimedRewards[2].rewardAmount, 5000000, "Hazel reward 2 balance");
    }

    function test_updateRewardsOnTransfer() public {
        uint256 amount_ = 10000 * 1e18;
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, true, false);

        MockERC20 rewardStrat1 = new MockERC20("Reward1", "R1", 6);
        MockERC20 rewardStrat1b = new MockERC20("Reward1b", "R1b", 6);
        MockERC20 rewardStrat2 = new MockERC20("Reward2", "R2", 6);
        MockERC4626(address(strats[0].strategy)).setRewardPrep(
            address(newVault),
            address(rewardStrat1),
            address(rewardStrat1b)
        );
        MockERC4626(address(strats[1].strategy)).setRewardPrep(address(newVault), address(rewardStrat2), address(0));
        uint256 hazelsAmount = amount_;
        asset.mint(hazel, 2 * hazelsAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), 2 * hazelsAmount);

        vm.prank(hazel);
        uint256 hazelShares = newVault.deposit(hazelsAmount, hazel);

        assertEq(newVault.userRewardIndex(hazel, address(rewardStrat1)), 0, "User reward 1 index");
        assertEq(newVault.userRewardIndex(hazel, address(rewardStrat2)), 0, "User reward 2 index");

        vm.prank(admin);
        newVault.harvestRewards("");

        vm.prank(hazel);
        newVault.transfer(jimmy, hazelShares);

        assertEq(10000000, rewardStrat1.balanceOf(address(hazel)), "Hazel reward 1 balance");
        assertEq(20000000, rewardStrat1b.balanceOf(address(hazel)), "Hazel reward 1b balance");
        assertEq(10000000, rewardStrat2.balanceOf(address(hazel)), "Hazel reward 2 balance");

        assertEq(0, rewardStrat1.balanceOf(address(jimmy)), "Jimmy reward 1 balance");

        uint256 rewardIndex1 = PRECISION.mulDiv(10000000, newVault.totalSupply(), Math.Rounding.Floor);

        assertEq(
            newVault.userRewardIndex(hazel, address(rewardStrat1)),
            newVault.rewardIndex(address(rewardStrat1)),
            "Reward indexes"
        );

        assertEq(newVault.userRewardIndex(jimmy, address(rewardStrat1)), rewardIndex1, "Jimmy reward 1 index");

        assertEq(newVault.totalRewardsClaimed(hazel, address(rewardStrat1)), 10000000, "Total rewards claimed");
        assertEq(newVault.totalRewardsClaimed(hazel, address(rewardStrat1b)), 20000000, "Total rewards claimed");
        assertEq(newVault.totalRewardsClaimed(hazel, address(rewardStrat2)), 10000000, "Total rewards claimed");

        ReturnedRewards[] memory claimedRewards = newVault.getTotalRewardsClaimed(address(hazel));
        assertEq(claimedRewards[0].rewardAmount, 10000000, "Hazel reward 1 address");
        assertEq(claimedRewards[1].rewardAmount, 20000000, "Hazel reward 1b address");
        assertEq(claimedRewards[2].rewardAmount, 10000000, "Hazel reward 2 address");
    }
    // ============= UTILITIES =========================

    function _createMockStrategy(IERC20 asset_, bool decreased_) internal returns (Strategy memory) {
        return
            Strategy({
                strategy: IStrategy(address(new MockERC4626(asset_, "Mock Shares", "MS"))),
                allocation: Allocation({index: 0, amount: decreased_ ? 1000 : 3333})
            });
    }

    function _createMockStrategyAvaliableZero(IERC20 asset_, bool decreased_) internal returns (Strategy memory) {
        return
            Strategy({
                strategy: IStrategy(address(new MockERC4626Queue(asset_, "Mock Shares", "MS"))),
                allocation: Allocation({index: 0, amount: decreased_ ? 1000 : 3333})
            });
    }

    function _createMockProstotectStrategy(IERC20 asset_, bool decreased_) internal returns (Strategy memory) {
        return
            Strategy({
                strategy: IStrategy(address(new MockERC4626Protect(asset_, "Mock Protect Shares", "MPS"))),
                allocation: Allocation({index: 0, amount: decreased_ ? 1000 : 3333})
            });
    }

    function _createNewVault(
        bool fees_,
        bool decreased_,
        bool avaliableForWithdrawZero
    ) internal returns (ConcreteMultiStrategyVault, Strategy[] memory) {
        Strategy[] memory strats = new Strategy[](3);
        if (avaliableForWithdrawZero) {
            strats[0] = _createMockStrategyAvaliableZero(IERC20(address(asset)), decreased_);
            strats[1] = _createMockStrategyAvaliableZero(IERC20(address(asset)), decreased_);
            strats[2] = _createMockStrategyAvaliableZero(IERC20(address(asset)), decreased_);
        } else {
            strats[0] = _createMockStrategy(IERC20(address(asset)), decreased_);
            strats[1] = _createMockStrategy(IERC20(address(asset)), decreased_);
            strats[2] = _createMockStrategy(IERC20(address(asset)), decreased_);
        }
        address vaultAddress = Clones.clone(implementation);
        ConcreteMultiStrategyVault newVault = ConcreteMultiStrategyVault(vaultAddress);
        newVault.initialize(
            IERC20(address(asset)),
            "Mock Vault",
            "MV",
            strats,
            feeRecipient,
            fees_
                ? VaultFees({depositFee: 100, withdrawalFee: 200, protocolFee: 2200, performanceFee: graduatedFees})
                : VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: zeroFees}),
            type(uint256).max,
            admin
        );
        return (newVault, strats);
    }

    function createQueue(
        uint256 amount_
    )
        public
        returns (
            ConcreteMultiStrategyVault _newVault,
            uint256 hazelsWithdrawalAmount,
            uint256 jimmysWithdrawalAmount,
            uint256 elliesWithdrawalAmount,
            WithdrawalQueue queue
        )
    {
        (ConcreteMultiStrategyVault newVault, Strategy[] memory strats) = _createNewVault(false, false, true);
        vm.assume(amount_ <= 100_000_000 * 1e18);
        vm.assume(amount_ > 0);
        amount_ = amount_ * 1e18;
        _newVault = newVault;

        queue = new WithdrawalQueue(address(newVault));
        vm.prank(admin);
        newVault.setWithdrawalQueue(address(queue));

        uint256 hazelsDespositedAmount = amount_;
        uint256 jimmysDespositedAmount = amount_ * 2;
        uint256 elliesDespositedAmount = amount_ / 3;
        asset.mint(hazel, hazelsDespositedAmount);
        asset.mint(jimmy, jimmysDespositedAmount);
        asset.mint(ellie, elliesDespositedAmount);
        vm.prank(hazel);
        asset.approve(address(newVault), hazelsDespositedAmount);
        vm.prank(jimmy);
        asset.approve(address(newVault), jimmysDespositedAmount);
        vm.prank(ellie);
        asset.approve(address(newVault), elliesDespositedAmount);

        vm.prank(hazel);
        newVault.deposit(hazelsDespositedAmount, hazel);
        vm.prank(jimmy);
        newVault.deposit(jimmysDespositedAmount, jimmy);
        vm.prank(ellie);
        newVault.deposit(elliesDespositedAmount, ellie);

        hazelsWithdrawalAmount = amount_;
        jimmysWithdrawalAmount = amount_ / 2;
        elliesWithdrawalAmount = amount_ / 15;
        vm.prank(hazel);
        newVault.withdraw(hazelsWithdrawalAmount, hazel, hazel);
        vm.prank(jimmy);
        newVault.withdraw(jimmysWithdrawalAmount, jimmy, jimmy);
        vm.prank(ellie);
        newVault.withdraw(elliesWithdrawalAmount, ellie, ellie);
        vm.prank(ellie);
        newVault.withdraw(elliesWithdrawalAmount, ellie, ellie);

        for (uint256 i = 0; i < strats.length; ) {
            IMockStrategy(address(strats[i].strategy)).setAvailableAssetsZero(false);
            unchecked {
                i++;
            }
        }
    }
}
