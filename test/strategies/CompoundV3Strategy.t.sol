//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../../src/strategies/StrategyBase.sol";
import {CompoundV3Strategy} from "../../src/strategies/compoundV3/CompoundV3Strategy.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICToken, ICometRewarder, IGovernor, IAdmin, ICometConfigurator, RewardConfig} from "../../src/strategies/compoundV3/ICompoundV3.sol";

contract CompoundV3StrategyTest is Test {
    using Math for uint256;

    // address cTokenAddress = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    // address rewarderAddress = 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
    // address compoundTokenAddress = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    // address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x2222);

    uint256 defaultAmount = 1e18;

    ICToken cToken;
    ICometRewarder rewarder;
    ICometConfigurator configurator;

    IERC20 asset;

    uint256 compoundDefaultAmount = 1e18;

    CompoundV3Strategy strategy;
    address rewarderAddress = 0x88730d254A2f7e6AC8388c3198aFd694bA9f7fae;
    address cTokenAddress = 0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf;
    address compoundTokenAddress = 0x354A6dA3fcde098F8389cad84b0182725c6C91dE;
    // address public constant WETH = 0x82af49447d8a07e3bd95bd0d56f35241523fbab1
    // vm.createFork("https://arb-mainnet.g.alchemy.com/v2/THuQ6WJZ6orCusOEvVFb9baHWzk_KG_D", 190_065_775);

    function setUp() public {
        // uint256 forkId = vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/XEXcx-FgF4-rMLVargS3LKPa9whsZ7vt");
        uint256 forkId = vm.createFork(
            "https://arb-mainnet.g.alchemy.com/v2/THuQ6WJZ6orCusOEvVFb9baHWzk_KG_D",
            228_050_914
        );
        vm.selectFork(forkId);
        _setUpTest();
    }

    // function test_deploy() public view {
    //     assertNotEq(address(strategy), address(0x0));
    // }

    function _setUpTest() internal {
        cToken = ICToken(cTokenAddress);
        rewarder = ICometRewarder(rewarderAddress);

        asset = IERC20(cToken.baseToken());

        strategy = new CompoundV3Strategy(
            IERC20(cToken.baseToken()),
            feeRecipient,
            admin,
            1000,
            address(rewarder),
            address(cToken),
            hazel
        );

        asset = IERC20(cToken.baseToken());

        vm.label(address(cToken), "aToken");
        vm.label(address(rewarder), "Rewarder");
        vm.label(address(cToken.baseToken()), "asset");
    }

    function test_initialize() public view {
        assertEq(strategy.asset(), cToken.baseToken(), "Asset Match");
        assertEq(IERC20Metadata(address(strategy)).name(), "Concrete Earn CompoundV3 USDC Strategy");
        assertEq(IERC20Metadata(address(strategy)).symbol(), "ctCM3-USDC");
        assertEq(
            IERC20(cToken.baseToken()).allowance(address(strategy), address(cToken)),
            type(uint256).max,
            "Max Allowance"
        ); //
    }

    function test_previewDeposit(uint256 amount) public {
        //uint256 amount = bound(amount_, 1e9, 1000 ether);
        vm.assume(amount >= 1e9 && amount <= 1000 ether);
        _mintAsset(amount, hazel);

        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);

        uint256 shares = strategy.previewDeposit(amount);
        assertEq(shares, amount);
    }

    function test_previewMint(uint256 amount) public {
        //uint256 amount = bound(amount_, 1e9, 1000 ether);
        vm.assume(amount >= 1e9 && amount <= 1000 ether);
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);

        uint256 assets = strategy.previewMint(amount);
        assertEq(assets, amount);
    }

    function test_previewWithdraw(uint256 amount) public {
        // uint256 amount = bound(amount_, 1e18, 1000 ether);
        vm.assume(amount >= 1e18 && amount <= 1000 ether);
        uint256 requestedAmt = strategy.previewMint(strategy.previewWithdraw(amount));
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        uint256 expectedWithdraw = strategy.previewWithdraw(amount);
        assertLe(requestedAmt, expectedWithdraw);
    }

    function test_previewRedeem(uint256 amount) public {
        //uint256 amount = bound(amount_, 1e18, 1000 ether);
        vm.assume(amount >= 1e18 && amount <= 1000 ether);
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

    function test_deposit(uint256 amount) public {
        //uint256 amount = bound(amount_, 1e10, 1000 ether);
        vm.assume(amount >= 1e10 && amount <= 1000 ether);
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        uint256 shares = strategy.deposit(amount, hazel);
        assertEq(asset.balanceOf(hazel), 0, "Hazel after balance");
        assertEq(shares, strategy.balanceOf(hazel), "Hazel share balance");

        uint256 bal = cTokenBal();
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

    function test_mint(uint256 amount) public {
        // uint256 amount = bound(amount_, 1e10, 1000 ether);
        vm.assume(amount >= 1e10 && amount <= 1000 ether);
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

    function test_harvestRewards() public {
        _mintAsset(defaultAmount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), defaultAmount);
        vm.prank(hazel);
        strategy.deposit(defaultAmount, hazel);

        increasePricePerShare(defaultAmount);

        vm.warp(block.timestamp + 100);
        _mintAsset(defaultAmount, hazel);
        vm.prank(hazel);
        //0xc00e94Cb662C3520282E6f5717214004A7f26888 == COMP tokens... (Reward Token)

        strategy.harvestRewards("");
        assertApproxEqAbs(
            IERC20(compoundTokenAddress).balanceOf(feeRecipient),
            1907700000000000,
            1e14,
            "Fee recipient balance"
        );

        assertEq(IERC20(compoundTokenAddress).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertApproxEqAbs(IERC20(compoundTokenAddress).balanceOf(hazel), 17169300000000000, 1e14, "Accrued Reward");
    }

    function test_getRewardsToStrat() public {
        _mintAsset(defaultAmount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), defaultAmount);
        vm.prank(hazel);
        uint256 shares = strategy.deposit(defaultAmount, hazel);

        increasePricePerShare(defaultAmount);

        vm.warp(block.timestamp + 100);
        _mintAsset(defaultAmount, hazel);

        //0xc00e94Cb662C3520282E6f5717214004A7f26888 == COMP tokens... (Reward Token)
        vm.prank(hazel);
        strategy.withdraw(shares, hazel, hazel);

        assertApproxEqAbs(
            IERC20(compoundTokenAddress).balanceOf(address(strategy)),
            1907700000000000 + 17169300000000000,
            1e14,
            "Accrued Reward"
        );
    }

    function increasePricePerShare(uint256 amount) public {
        deal(address(asset), address(cToken), asset.balanceOf(address(cToken)) + amount);
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

    function cTokenBal() public view returns (uint256) {
        return cToken.balanceOf(address(strategy));
    }
}
