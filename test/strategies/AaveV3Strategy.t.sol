//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../../src/strategies/StrategyBase.sol";
import {MockERC20} from "../../test/utils/mocks/MockERC20.sol";
import {AaveV3Strategy} from "../../src/strategies/Aave/AaveV3Strategy.sol";
import {IAToken, ILendingPool, IAaveIncentives, IProtocolDataProvider} from "../../src/strategies/Aave/IAaveV3.sol";
import {DataTypes} from "../../src/strategies/Aave/DataTypes.sol";

contract AaveV3StrategyTest is Test {
    using Math for uint256;

    address rewardToken = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x2222);

    uint256 defaultAmount = 10 * 1e18;

    ILendingPool lendingPool;
    IAaveIncentives aaveIncentives;
    IAToken aToken;
    IERC20 asset;

    AaveV3Strategy strategy;

    function setUp() public {
        uint256 forkId = vm.createFork(
            "https://arb-mainnet.g.alchemy.com/v2/THuQ6WJZ6orCusOEvVFb9baHWzk_KG_D",
            223_500_507
        );
        vm.selectFork(forkId);
        _setUpTest(WETH, 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);
    }

    function _setUpTest(address asset_, address aaveDataProvider_) internal {
        (address _aToken, , ) = IProtocolDataProvider(aaveDataProvider_).getReserveTokensAddresses(asset_);
        aToken = IAToken(_aToken);
        lendingPool = ILendingPool(aToken.POOL());
        aaveIncentives = IAaveIncentives(aToken.getIncentivesController());

        strategy = new AaveV3Strategy(IERC20(asset_), feeRecipient, admin, 1000, aaveDataProvider_, hazel);

        asset = IERC20(asset_);

        vm.label(address(aToken), "aToken");
        vm.label(address(lendingPool), "lendingPool");
        vm.label(address(asset_), "asset");
    }

    function test_initialize() public view {
        assertEq(strategy.asset(), aToken.UNDERLYING_ASSET_ADDRESS(), "Asset Match");
        assertEq(IERC20Metadata(address(strategy)).name(), "Concrete Earn AaveV3 WETH Strategy");
        assertEq(IERC20Metadata(address(strategy)).symbol(), "ctAv3-WETH");
        assertEq(IERC20(WETH).allowance(address(strategy), address(lendingPool)), type(uint256).max, "Max Allowance");
    }

    function test_previewDeposit(uint256 amount) public {
        _mintAsset(amount, hazel);

        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);

        uint256 shares = strategy.previewDeposit(amount);
        assertEq(shares, amount);
    }

    function test_previewMint(uint256 amount) public {
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);

        uint256 assets = strategy.previewMint(amount);
        assertEq(assets, amount);
    }

    function test_previewWithdraw(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e18, 1000 ether);
        uint256 requestedAmt = strategy.previewMint(strategy.previewWithdraw(amount));
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        uint256 expectedWithdraw = strategy.previewWithdraw(amount);
        assertLe(requestedAmt, expectedWithdraw);
    }

    function test_previewRedeem(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e18, 1000 ether);
        uint256 reqAssets = strategy.previewMint(amount) * 10;
        _mintAsset(reqAssets, hazel);

        vm.prank(hazel);
        asset.approve(address(strategy), reqAssets);

        vm.prank(hazel);
        uint256 shares = strategy.deposit(reqAssets, hazel);

        uint256 preview = strategy.previewRedeem(shares);
        vm.prank(hazel);
        uint256 actual = strategy.redeem(shares, hazel, hazel);
        assertGe(actual, preview);
    }

    function test_deposit(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        uint256 shares = strategy.deposit(amount, hazel);
        assertEq(asset.balanceOf(hazel), 0, "Hazel after balance");
        assertEq(shares, strategy.balanceOf(hazel), "Hazel share balance");

        uint256 bal = aTokenBal();
        assertApproxEqAbs(bal, amount, 0.000001 ether, "Balance of aToken");
    }

    function test_failDepositZero() public {
        uint256 amount = 0;
        _mintAsset(10 ether, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), 10 ether);

        vm.prank(hazel);
        vm.expectRevert();
        strategy.deposit(amount, hazel);
    }

    function test_mint(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        _mintAsset(strategy.previewMint(amount), hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        uint256 shares = strategy.mint(amount, hazel);
        assertEq(strategy.balanceOf(hazel), shares, "Hazel share balance");
    }

    function test_failMintZero() public {
        uint256 amount = 0;
        vm.expectRevert();
        vm.prank(hazel);
        strategy.mint(amount, hazel);
    }

    function test_withdraw(uint256 amount_) public {
        vm.startPrank(hazel);
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        _mintAsset(amount, hazel);

        asset.approve(address(strategy), amount);

        uint256 shares = strategy.deposit(amount, hazel);

        assertEq(asset.balanceOf(hazel), 0, "Hazel asset balance");
        assertEq(shares, amount, "Hazel share balance == amount");

        strategy.withdraw(strategy.maxWithdraw(hazel), hazel, hazel);

        assertLe(asset.balanceOf(hazel), amount, "Hazel new asset balance");
        assertEq(strategy.balanceOf(hazel), 0, "Hazel new share balance");
        vm.stopPrank();
    }

    function test_redeem(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        _mintAsset(strategy.previewMint(amount), hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);

        vm.prank(hazel);
        strategy.mint(amount, hazel);

        vm.prank(hazel);
        uint256 assets = strategy.redeem(amount, hazel, hazel);
        assertLe(assets, amount, "Hazel new asset balance");
        assertEq(strategy.balanceOf(hazel), 0, "Hazel new share balance");
    }

    function test_harvest() public {
        _setUpTest(USDC, 0x6b4E260b765B3cA1514e618C0215A6B7839fF93e);
        uint256 amount = 1000000000;
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        strategy.deposit(amount, hazel);
        vm.warp(block.timestamp + 100);
        vm.prank(hazel);
        strategy.harvestRewards("");

        assertGe(IERC20(rewardToken).balanceOf(feeRecipient), 0, "Fee recipient balance");

        assertEq(IERC20(rewardToken).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertGe(IERC20(rewardToken).balanceOf(hazel), 0, "Accrued Reward");
    }

    function test_totalAssets() public {
        // Make sure totalAssets isnt 0
        deal(address(asset), hazel, defaultAmount);
        vm.startPrank(hazel);
        asset.approve(address(strategy), defaultAmount);
        strategy.deposit(defaultAmount, hazel);
        vm.stopPrank();

        assertEq(strategy.totalAssets(), strategy.convertToAssets(strategy.totalSupply()), "Total supply converted");
    }

    function _mintAsset(uint256 amount_, address to_) internal {
        deal(address(asset), to_, amount_);
    }

    function aTokenBal() public view returns (uint256) {
        return aToken.balanceOf(address(strategy));
    }

    function inflate(uint256 amount) public {
        deal(address(WETH), address(aToken), IERC20(WETH).balanceOf(address(aToken)) + amount);
    }
}
