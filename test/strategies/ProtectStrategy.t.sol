//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockERC20} from "../../test/utils/mocks/MockERC20.sol";
import {ConcreteMultiStrategyVault} from "../../src/vault/ConcreteMultiStrategyVault.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strategy, VaultFees, Allocation, GraduatedFee} from "../../src/interfaces/IConcreteMultiStrategyVault.sol";
import {Errors} from "../../src/interfaces/Errors.sol";
import {MockERC4626} from "../utils/mocks/MockERC4626.sol";
import {MockERC4626Protect} from "../utils/mocks/MockERC4626Protect.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";
import {IProtectStrategy} from "../../src/interfaces/IProtectStrategy.sol";
import {ProtectStrategy} from "../../src/strategies/ProtectStrategy/ProtectStrategy.sol";

contract ProtectStrategyTest is Test {
    using Math for uint256;

    GraduatedFee[] zeroFees;

    address jimmy = address(0x1111);
    address feeRecipient = address(0x2222);
    address admin = address(0x4444);
    address fakeClaimRouter = address(0x5555);
    MockERC20 fakeETH;

    address implementation;

    ConcreteMultiStrategyVault ethVault1;

    function setUp() public {
        fakeETH = new MockERC20("FakeETH", "FETH", 18);
        implementation = address(new ConcreteMultiStrategyVault());

        zeroFees.push(GraduatedFee({lowerBound: 0, upperBound: 10000, fee: 0}));

        ethVault1 = _createVault(fakeETH);
    }

    function _createVault(ERC20 asset) internal returns (ConcreteMultiStrategyVault) {
        string memory symbol = asset.symbol();

        ConcreteMultiStrategyVault newVault = ConcreteMultiStrategyVault(Clones.clone(implementation));
        Strategy[] memory newStrategy = new Strategy[](3);
        newStrategy[0] = Strategy({
            strategy: new MockERC4626(asset, string.concat("Mock 1", symbol, " Shares"), string.concat("S", symbol)),
            allocation: Allocation({index: 0, amount: 3333})
        });
        newStrategy[1] = Strategy({
            strategy: new MockERC4626(asset, string.concat("Mock 2", symbol, " Shares"), string.concat("S", symbol)),
            allocation: Allocation({index: 0, amount: 3333})
        });
        newStrategy[2] = Strategy({
            strategy: new ProtectStrategy(asset, feeRecipient, admin, fakeClaimRouter, address(newVault)),
            allocation: Allocation({index: 0, amount: 3333})
        });

        newVault.initialize(
            ERC20(address(asset)),
            string.concat("Vault ", symbol, "Shares"),
            string.concat("V", symbol),
            newStrategy,
            feeRecipient,
            VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: zeroFees}),
            type(uint256).max,
            admin
        );

        return newVault;
    }

    function test_deploy() public {
        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        assertEq(ethVault1.protectStrategy(), strategy, "Protect Strategy not set correctly");
        IProtectStrategy protect = IProtectStrategy(strategy);
        assertEq(protect.isProtectStrategy(), true, "Protect Strategy not set to true");
    }

    function test_ShouldSetClaimRouter() public {
        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        IProtectStrategy protect = IProtectStrategy(strategy);
        assertEq(protect.claimRouter(), fakeClaimRouter, "ClaimRouter");
        vm.prank(admin);
        protect.setClaimRouter(address(0x1));
        assertEq(protect.claimRouter(), address(0x1), "new ClaimRouter");
    }

    function test_ShouldFailSetClaimRouterIfTheCallerisNotTheOwner() public {
        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        IProtectStrategy protect = IProtectStrategy(strategy);
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this));

        vm.expectRevert(encodedError);
        protect.setClaimRouter(address(0x1));
    }

    function test_ShouldTransferToRecipientIfItHasEnoughBalance() public {
        uint256 amount = 10000 ether;
        fakeETH.mint(jimmy, amount);

        vm.startPrank(jimmy);
        fakeETH.approve(address(ethVault1), amount);
        ethVault1.deposit(amount);
        vm.stopPrank();

        assertEq(ethVault1.balanceOf(jimmy), amount * 1e9, "ETH Vault Balance not correct");

        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        uint256 protectStratBalance = fakeETH.balanceOf(strategy);

        IProtectStrategy protect = IProtectStrategy(strategy);

        assertEq(protect.getBorrowDebt(), 0, "Protect Strategy borrow debt must be 0");
        assertEq(fakeETH.balanceOf(strategy), protect.totalAssets(), "Protect Strategy balance not correct");
        uint256 previewSharesBefore = protect.previewDeposit(amount);
        vm.prank(fakeClaimRouter);
        protect.executeBorrowClaim(protectStratBalance, fakeClaimRouter);

        assertEq(protect.getBorrowDebt(), protect.totalAssets(), "Protect Strategy borrow equal to previous balance");
        assertEq(fakeETH.balanceOf(fakeClaimRouter), protectStratBalance, "Claim Router balance not correct");
        uint256 previewSharesAfter = protect.previewDeposit(amount);
        assertEq(previewSharesAfter, previewSharesBefore, "Preview shares not correct");

        vm.prank(fakeClaimRouter);
        protect.updateBorrowDebt(protectStratBalance);
        assertEq(protect.getBorrowDebt(), 0, "Protect Strategy borrow equal to 0");
    }

    function test_ShouldBorrowFromTheVaultIfNotEnoughBalanceInProtect() public {
        uint256 amount = 10000 ether;
        fakeETH.mint(jimmy, amount);

        vm.startPrank(jimmy);
        fakeETH.approve(address(ethVault1), amount);
        ethVault1.deposit(amount);
        vm.stopPrank();

        fakeETH.mint(address(ethVault1), amount);
        assertEq(ethVault1.balanceOf(jimmy), amount * 1e9, "ETH Vault Balance not correct");

        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        IProtectStrategy protect = IProtectStrategy(strategy);
        uint256 protectStratBalance = fakeETH.balanceOf(strategy);

        uint256 vaultPreviousBalance = fakeETH.balanceOf(address(ethVault1));

        vm.prank(fakeClaimRouter);
        protect.executeBorrowClaim(2 * protectStratBalance, fakeClaimRouter);

        assertEq(
            2 * protectStratBalance,
            protect.totalAssets(),
            "Protect Strategy total assets equal to double of previus balance"
        );
        assertEq(
            fakeETH.balanceOf(address(ethVault1)),
            vaultPreviousBalance - protectStratBalance,
            "Balance of Vault not correct after borrowing"
        );
        assertEq(protect.getBorrowDebt(), protect.totalAssets(), "Protect Strategy borrow equal to previous balance");

        //borrow again, the balance of the vault, and the amount in the other two strats
        uint256 toBorrow = fakeETH.balanceOf(address(ethVault1)) + 2 * protectStratBalance;
        vm.prank(fakeClaimRouter);
        protect.executeBorrowClaim(toBorrow, fakeClaimRouter);

        assertEq(fakeETH.balanceOf(address(strats[0].strategy)), 0, "first Strategy total assets equal to 0");
        assertEq(fakeETH.balanceOf(address(strats[1].strategy)), 0, "second Strategy total assets equal to 0");
        assertEq(ethVault1.totalAssets(), amount * 2, "Balance of Vault not correct after borrowing");
        assertEq(protect.totalAssets(), amount * 2, "Balance of protect strat not correct after borrowing");
    }

    function testfail_ShouldRevertIfTriesToBorrowMoreThanVaultBalance() public {
        uint256 amount = 10000 ether;
        fakeETH.mint(jimmy, amount);

        vm.startPrank(jimmy);
        fakeETH.approve(address(ethVault1), amount);
        ethVault1.deposit(amount);
        vm.stopPrank();

        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        IProtectStrategy protect = IProtectStrategy(strategy);
        uint256 protectStratBalance = fakeETH.balanceOf(strategy);

        bytes memory encodedError = abi.encodeWithSelector(
            Errors.InsufficientFunds.selector,
            address(ethVault1),
            amount - protectStratBalance + 10,
            amount - protectStratBalance
        );
        vm.expectRevert(encodedError);
        vm.prank(fakeClaimRouter);
        protect.executeBorrowClaim(amount + 10, fakeClaimRouter);
    }

    function testfail_ShouldRevertIfCallerIsNotTheClaimRouter() public {
        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);
        IProtectStrategy protect = IProtectStrategy(strategy);

        bytes memory encodedError = abi.encodeWithSelector(Errors.ClaimRouterUnauthorizedAccount.selector, jimmy);
        vm.expectRevert(encodedError);
        vm.prank(jimmy);
        protect.executeBorrowClaim(1000, jimmy);
    }

    function testfail_ShouldRevertIfSubstractsFromDebtMoreThanBorrowDebt() public {
        uint256 amount = 10000 ether;
        fakeETH.mint(jimmy, amount);

        vm.startPrank(jimmy);
        fakeETH.approve(address(ethVault1), amount);
        ethVault1.deposit(amount);
        vm.stopPrank();

        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);

        IProtectStrategy protect = IProtectStrategy(strategy);

        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidSubstraction.selector);

        vm.prank(fakeClaimRouter);
        vm.expectRevert(encodedError);
        protect.updateBorrowDebt(amount);
    }

    function testfail_ShouldRevertIfCallerIsNotTheClaimRouterInUpdateBorrowDebt() public {
        uint256 amount = 10000 ether;

        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[2].strategy);

        IProtectStrategy protect = IProtectStrategy(strategy);

        bytes memory encodedError = abi.encodeWithSelector(
            Errors.ClaimRouterUnauthorizedAccount.selector,
            address(this)
        );

        vm.expectRevert(encodedError);
        protect.updateBorrowDebt(amount);
    }
}
