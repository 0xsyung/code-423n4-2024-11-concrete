//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../../src/strategies/StrategyBase.sol";
import {MockERC20} from "../../test/utils/mocks/MockERC20.sol";
import {RadiantV2Strategy} from "../../src/strategies/Radiant/RadiantV2Strategy.sol";
import {IAToken, ILendingPool, IChefIncentivesController, ILendingPoolAddressesProvider} from "../../src/strategies/Radiant/IRadiantV2.sol";
import {DataTypes} from "../../src/strategies/Radiant/DataTypes.sol";

contract RadiantV2StrategyTest is Test {
    using Math for uint256;
    // address public constant WETH = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public constant WETH = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant addressProvider = 0x70e507f1d20AeC229F435cd1EcaC6A7200119B9F;
    // address public constant addressProvider = 0x091d52CacE1edc5527C99cDCFA6937C1635330E4;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x2222);

    uint256 defaultAmount = 10 * 1e18;

    ILendingPool lendingPool;
    IChefIncentivesController incentiveController;
    IAToken aToken;
    IERC20 asset;

    RadiantV2Strategy strategy;

    function setUp() public {
        // uint256 forkId =
        // vm.createFork("https://arb-mainnet.g.alchemy.com/v2/THuQ6WJZ6orCusOEvVFb9baHWzk_KG_D", 190_065_775);
        // uint256 forkId = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/XEXcx-FgF4-rMLVargS3LKPa9whsZ7vt");
        uint256 forkId = vm.createFork("https://mainnet.gateway.tenderly.co/6G89IE1Yv6GhSIbQnx3wqw", 20_090_000);
        vm.selectFork(forkId);
        _setUpTest(WETH, addressProvider);
    }

    function _setUpTest(address asset_, address addressProvider_) internal {
        lendingPool = ILendingPool(ILendingPoolAddressesProvider(addressProvider_).getLendingPool());
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset_);
        aToken = IAToken(reserveData.aTokenAddress);
        incentiveController = IChefIncentivesController(aToken.getIncentivesController());
        strategy = new RadiantV2Strategy(IERC20(asset_), feeRecipient, admin, 1000, addressProvider, hazel);
        asset = IERC20(asset_);
        vm.label(address(aToken), "aToken");
        vm.label(address(lendingPool), "lendingPool");
        vm.label(address(asset_), "asset");
    }

    function test_initialize() public view {
        console.log("aToken", address(aToken));
        console.log("lendingPool", address(lendingPool));
        console.log("asset", address(asset));
        console.log("incentiveController", address(incentiveController));
        assertEq(strategy.asset(), aToken.UNDERLYING_ASSET_ADDRESS(), "Asset Match");
        assertEq(IERC20Metadata(address(strategy)).name(), "Concrete Earn RadiantV2 WETH Strategy");
        assertEq(IERC20Metadata(address(strategy)).symbol(), "ctRdV2-WETH");
        assertEq(IERC20(WETH).allowance(address(strategy), address(lendingPool)), type(uint256).max, "Max Allowance");
    }

    function test_isProtectStrategy() public view {
        assertEq(strategy.isProtectStrategy(), false);
    }

    function test_previewDeposit(uint256 amount) public {
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);
        uint256 shares = strategy.previewDeposit(amount);
        assertEq(shares, amount);
    }

    function test_previewDepositV2(uint256 amount) public {
        _mintAsset(amount, hazel);
        // transfer 10% of amount to strategy to change the asset ratio
        uint256 transferAmount = amount / 10;
        _mintAsset(transferAmount, address(strategy));
        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);
        uint256 shares = strategy.previewDeposit(amount);
        uint256 expectedShares = _convertToShares(amount, 0, transferAmount, Math.Rounding.Floor);
        assertEq(shares, expectedShares);
    }

    function test_previewMint(uint256 amount) public {
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), type(uint256).max);

        uint256 assets = strategy.previewMint(amount);
        assertEq(assets, amount);
    }

    function test_previewWithdraw(uint256 amount_) public view {
        uint256 shares = strategy.previewWithdraw(amount_);
        assertLe(amount_, shares);
    }

    function test_previewWithdrawV2(uint256 amount_) public {
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

    function test_previewWithdrawV3() public {
        uint256 amount = 100;
        uint256 transferAmount = amount / 10;
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        strategy.deposit(amount, hazel);
        _mintAsset(transferAmount, address(strategy));
        uint256 shares = strategy.previewWithdraw(amount);
        uint256 expectedShares = _convertToShares(amount, amount, amount + transferAmount, Math.Rounding.Ceil);
        assertEq(shares, expectedShares);
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
        vm.prank(hazel);
        vm.expectRevert();
        strategy.deposit(amount, hazel);
    }

    function test_mint(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        uint256 reqAssets = strategy.previewMint(amount);
        _mintAsset(reqAssets, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        uint256 shares = strategy.mint(amount, hazel);
        assertEq(shares, amount);
        assertApproxEqAbs(reqAssets, strategy.convertToAssets(strategy.balanceOf(hazel)), 0.000001 ether);
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

    function test_getRewardTokenAddresses() public view {
        address[] memory rewardTokenAddresses = strategy.getRewardTokenAddresses();
        assertEq(rewardTokenAddresses.length, 0);
    }

    function test_setEnableRewardsUnauthorized() public {
        vm.expectRevert();
        vm.prank(hazel);
        strategy.setEnableRewards(true);
    }

    function test_setEnableRewards() public {
        assertEq(strategy.rewardsEnabled(), false);

        vm.startPrank(admin);
        strategy.setEnableRewards(true);
        assertEq(strategy.rewardsEnabled(), true);
        // test for event
        strategy.setEnableRewards(false);
        assertEq(strategy.rewardsEnabled(), false);
        vm.stopPrank();
    }

    function test_getAvailableAssetsForWithdrawal() public {
        uint256 amount = 100 ether;
        assertEq(strategy.getAvailableAssetsForWithdrawal(), 0);
        _mintAsset(amount, hazel);

        vm.startPrank(hazel);
        asset.approve(address(strategy), amount);
        strategy.deposit(amount, hazel);
        assertEq(strategy.getAvailableAssetsForWithdrawal(), amount);
        vm.stopPrank();
    }

    function test_retireStrategyUnauthorised() public {
        vm.expectRevert();
        vm.prank(hazel);
        strategy.retireStrategy();
    }

    function test_retireStrategy() public {
        uint256 amount = 100 ether;
        _mintAsset(amount, hazel);

        vm.startPrank(hazel);
        asset.approve(address(strategy), amount);
        strategy.deposit(amount, hazel);
        assertApproxEqAbs(aTokenBal(), amount, 0.000001 ether);
        vm.stopPrank();

        vm.startPrank(admin);
        strategy.retireStrategy();
        assertEq(aTokenBal(), 0);
        vm.stopPrank();
    }

    function test_totalAssets() public {
        // Make sure totalAssets isnt 0
        deal(address(asset), hazel, defaultAmount);
        vm.startPrank(hazel);
        asset.approve(address(strategy), defaultAmount);
        strategy.deposit(defaultAmount, hazel);
        vm.stopPrank();
        assertEq(strategy.totalAssets(), defaultAmount);
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

    function _convertToShares(
        uint256 assets,
        uint256 _totalSupply,
        uint256 _totalAssets,
        Math.Rounding rounding
    ) internal view virtual returns (uint256) {
        return assets.mulDiv(_totalSupply + 10 ** _decimalsOffset(), _totalAssets + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(
        uint256 shares,
        uint256 _totalAssets,
        uint256 _totalSupply,
        Math.Rounding rounding
    ) internal view virtual returns (uint256) {
        return shares.mulDiv(_totalAssets + 1, _totalSupply + 10 ** _decimalsOffset(), rounding);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}
