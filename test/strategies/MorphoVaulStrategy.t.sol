//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../../src/strategies/StrategyBase.sol";
import {MockERC20} from "../../test/utils/mocks/MockERC20.sol";
import {MorphoVaultStrategy} from "../../src/strategies/Morpho/MorphoVaultStrategy.sol";

import {DataTypes} from "../../src/strategies/Aave/DataTypes.sol";

contract MorphoVaultStrategyTest is Test {
    using Math for uint256;

    //WETH Vault
    address morphoVaultAddress = 0x38989BBA00BDF8181F4082995b3DEAe96163aC5D;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x2222);

    uint256 defaultAmount = 10 * 1e18;

    IERC20 asset;

    MorphoVaultStrategy strategy;

    function setUp() public {
        uint256 forkId = vm.createFork(
            "https://eth-mainnet.g.alchemy.com/v2/XEXcx-FgF4-rMLVargS3LKPa9whsZ7vt",
            21023433
        );
        vm.selectFork(forkId);
        _setUpTest(WETH);
    }

    function _setUpTest(address asset_) internal {
        strategy = new MorphoVaultStrategy(IERC20(asset_), feeRecipient, admin, 1000, morphoVaultAddress, hazel);

        asset = IERC20(asset_);

        vm.label(address(asset_), "asset");
    }

    function test_initialize() public view {
        assertEq(strategy.asset(), IERC4626(morphoVaultAddress).asset(), "Asset Match");
        assertEq(IERC20Metadata(address(strategy)).name(), "Concrete Morpho Vault bbETH Strategy");
        assertEq(IERC20Metadata(address(strategy)).symbol(), "ctMV1-bbETH");
        assertEq(IERC20(WETH).allowance(address(strategy), morphoVaultAddress), type(uint256).max, "Max Allowance");
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

        uint256 bal = morphoTokenBalance();
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

    function test_withdraw_SharesPriceIncreased(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        vm.startPrank(hazel);
        // uint256 amount = bound(amount_, 1e10, 1000 ether);
        _mintAsset(amount, hazel);

        asset.approve(address(strategy), amount);
        uint256 shares = strategy.deposit(amount, hazel);

        assertEq(asset.balanceOf(hazel), 0, "Hazel asset balance");
        assertEq(shares, amount, "Hazel share balance == amount");

        vm.warp(block.timestamp + 100000);

        uint256 newAmount = strategy.maxWithdraw(hazel);
        assertGe(newAmount, amount, "Hazel new asset balance");
        vm.stopPrank();
    }

    // function test_harvest() public {
    //     //checking that does not revert
    //     uint256 amount = 1000000000;
    //     _mintAsset(amount, hazel);
    //     vm.prank(hazel);
    //     asset.approve(address(strategy), amount);

    //     vm.prank(hazel);
    //     strategy.deposit(amount, hazel);
    //     vm.warp(block.timestamp + 100);
    //     vm.prank(hazel);
    //     strategy.harvestRewards("");
    // }

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

    function morphoTokenBalance() public view returns (uint256) {
        return IERC4626(morphoVaultAddress).previewRedeem(IERC4626(morphoVaultAddress).balanceOf(address(strategy)));
    }
}
