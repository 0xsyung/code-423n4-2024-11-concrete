//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../../src/strategies/StrategyBase.sol";
import {MockERC20} from "../../test/utils/mocks/MockERC20.sol";
import {ISilo, ISiloRepository, ISiloIncentivesController} from "../../src/strategies/Silo/ISiloV1.sol";
import {SiloV1Strategy} from "../../src/strategies/Silo/SiloV1Strategy.sol";

/**
 * Silo strategy have 2 types of assets to deposit in a single market a. silo asset b. bridge asset
 * the default testcases are for bridge assets. while siloAsset testcases are marked explicitely.
 * example: test_depositsiloAsset()
 */
contract SiloV1StrategyTest is Test {
    using Math for uint256;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant siloAsset = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address public constant siloLens = 0x0e466FC22386997daC23D1f89A43ecb2CB1e76E9;
    address public constant siloRepository = 0xd998C35B7900b344bbBe6555cc11576942Cf309d;
    address public constant siloIncentivesController = 0x6c1603aB6CecF89DD60C24530DdE23F97DA3C229;
    address[] public extraRewardAssets;
    uint256[] public extraRewardFees;
    address feeRecipient = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x2222);
    address rewardToken;
    uint256 defaultAmount = 10 * 1e18;

    ISilo silo;
    IERC20 collateralToken;
    IERC20 asset;
    IERC20 arbToken;
    uint256 arbRewardAmount = 10000;
    SiloV1Strategy strategy;

    function setUp() public {
        uint256 forkId = vm.createFork("https://mainnet.gateway.tenderly.co/6G89IE1Yv6GhSIbQnx3wqw", 20189961);
        vm.selectFork(forkId);
        _setUpTest(WETH);
    }

    function _setUpTest(address asset_) internal {
        strategy = new SiloV1Strategy(
            IERC20Metadata(asset_),
            feeRecipient,
            admin,
            1000,
            siloAsset,
            siloRepository,
            siloIncentivesController,
            extraRewardAssets,
            extraRewardFees,
            hazel
        );
        rewardToken = ISiloIncentivesController(siloIncentivesController).REWARD_TOKEN();
        console.log("strategy", address(strategy));
        asset = IERC20(asset_);
        vm.label(address(asset_), "asset");
    }

    function test_initialize() public {
        console.log("asset", address(asset));
        console.log("incentiveController", siloIncentivesController);
        silo = ISilo(ISiloRepository(siloRepository).getSilo(siloAsset));
        collateralToken = IERC20(silo.assetStorage(strategy.asset()).collateralToken);
        console.log("silo", address(silo));
        console.log("collateralToken", address(collateralToken));
        assertEq(strategy.asset(), WETH, "Asset Match");
        assertEq(address(silo), address(strategy.silo()), "Silo Match");
        assertEq(IERC20Metadata(address(strategy)).name(), "Concrete Earn SiloV1 WETH Strategy");
        assertEq(IERC20Metadata(address(strategy)).symbol(), "ctSlV1-WETH");
        assertEq(IERC20(WETH).allowance(address(strategy), address(silo)), type(uint256).max, "Max Allowance");
    }

    function test_InvalidBridgeAsset() public {
        vm.expectRevert();
        _setUpTest(address(0x1234));
    }

    function test_isProtectStrategyS() public view {
        assertEq(strategy.isProtectStrategy(), false);
    }

    function test_previewDeposit(uint256 amount) public {
        amount = defaultAmount;
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

    function test_previewWithdraw(uint256 amount_) public view {
        uint256 shares = strategy.previewWithdraw(amount_);
        assertLe(amount_, shares);
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

        uint256 bal = balanceOfUnderlaying(collateralTokenBal());
        assertApproxEqAbs(bal, amount, 0.000001 ether, "Balance of aToken");
    }

    function test_depositSiloAsset(uint256 amount_) public {
        uint256 amount = bound(amount_, 1e10, 1000 ether);
        _setUpTest(siloAsset);
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);
        vm.prank(hazel);
        uint256 shares = strategy.deposit(amount, hazel);
        uint256 hazelBal = asset.balanceOf(hazel);
        assertEq(hazelBal, 0, "Hazel after balance");
        assertEq(shares, strategy.balanceOf(hazel), "Hazel share balance");

        uint256 bal = balanceOfUnderlaying(collateralTokenBal());
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
        asset.approve(address(strategy), reqAssets);

        vm.prank(hazel);
        uint256 shares = strategy.mint(amount, hazel);
        assertEq(shares, amount);
        assertApproxEqAbs(reqAssets, balanceOfUnderlaying(collateralTokenBal()), 0.000001 ether);
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

    function test_withdrawSiloAsset(uint256 amount_) public {
        _setUpTest(siloAsset);
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

    function test_harvest() public {
        // Silo rewards: Yes, Extra rewards: No
        uint256 amount = 1000000000;

        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);
        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        vm.warp(block.timestamp + 500);

        vm.prank(hazel);
        strategy.harvestRewards("");

        assertEq(IERC20(rewardToken).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertGe(IERC20(rewardToken).balanceOf(hazel), 0, "Accrued Reward");
        assertGe(IERC20(rewardToken).balanceOf(feeRecipient), 0, "Fee recipient balance");
    }

    function test_harvestWithSiloAndExtraRewards() public {
        // Silo rewards: Yes, Extra rewards: Yes
        arbToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        extraRewardAssets.push(address(arbToken));
        extraRewardFees.push(1000);
        // uint256 extraRewardAssetsLen = extraRewardAssets.length;
        // uint256 extraRewardFeesLen = extraRewardFees.length;
        _setUpTest(WETH);

        uint256 amount = 1000000000;
        _mintAsset(amount, hazel);

        vm.prank(hazel);
        asset.approve(address(strategy), amount);
        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        vm.warp(block.timestamp + 500);

        // mock for claim rewards from backend
        deal(address(arbToken), address(strategy), arbRewardAmount);

        vm.prank(hazel);
        strategy.harvestRewards("");
        // test for silo reward
        assertEq(IERC20(rewardToken).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertGe(IERC20(rewardToken).balanceOf(hazel), 0, "Accrued Reward");

        // test for arbToken rewards
        assertGe(arbToken.balanceOf(address(strategy)), 0, "Extra reward token balance");
        assertGe(arbToken.balanceOf(hazel), 0, "Extra reward token balance");
        assertGe(arbToken.balanceOf(feeRecipient), 0, "Fee Receipient token balance");
    }

    function test_harvestWithNoRewards() public {
        // Silo rewards: No, Extra rewards: No
        // cvx silo market
        address newSiloAsset = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
        strategy = new SiloV1Strategy(
            IERC20Metadata(newSiloAsset),
            feeRecipient,
            admin,
            1000,
            newSiloAsset,
            siloRepository,
            siloIncentivesController,
            extraRewardAssets,
            extraRewardFees,
            hazel
        );
        asset = IERC20(newSiloAsset);
        rewardToken = ISiloIncentivesController(siloIncentivesController).REWARD_TOKEN();
        uint256 amount = 1000000000;

        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);
        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        vm.warp(block.timestamp + 500);

        vm.prank(hazel);
        strategy.harvestRewards("");
        uint256 rewardBal = IERC20(rewardToken).balanceOf(address(strategy));
        assertEq(rewardBal, 0, "Fee recipient balance");

        assertEq(IERC20(rewardToken).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertEq(IERC20(rewardToken).balanceOf(hazel), 0, "Accrued Reward");
    }

    function test_harvestWithExtraRewards() public {
        // Silo rewards: No, Extra rewards: Yes
        address newSiloAsset = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
        arbToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        extraRewardAssets.push(address(arbToken));
        extraRewardFees.push(1000);
        // uint256 extraRewardAssetsLen = extraRewardAssets.length;
        // uint256 extraRewardFeesLen = extraRewardFees.length;

        strategy = new SiloV1Strategy(
            IERC20Metadata(newSiloAsset),
            feeRecipient,
            admin,
            1000,
            newSiloAsset,
            siloRepository,
            siloIncentivesController,
            extraRewardAssets,
            extraRewardFees,
            hazel
        );
        asset = IERC20(newSiloAsset);
        rewardToken = ISiloIncentivesController(siloIncentivesController).REWARD_TOKEN();
        uint256 amount = 1000000000;

        vm.startPrank(hazel);
        _mintAsset(amount, hazel);
        asset.approve(address(strategy), amount);
        strategy.deposit(amount, hazel);
        vm.stopPrank();

        vm.warp(block.timestamp + 500);

        // mock for claim rewards from backend
        deal(address(arbToken), address(strategy), arbRewardAmount);

        vm.prank(hazel);
        strategy.harvestRewards("");

        // test for silo reward token
        assertEq(IERC20(rewardToken).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertEq(IERC20(rewardToken).balanceOf(hazel), 0, "Accrued Reward");

        // test for arb reward token
        assertGe(IERC20(arbToken).balanceOf(address(strategy)), 0, "Extra reward token balance");
        assertGe(IERC20(arbToken).balanceOf(hazel), 0, "Extra reward token balance");
        assertGe(IERC20(arbToken).balanceOf(feeRecipient), 0, "Fee Receipient token balance");
    }

    function test_harvestSiloAsset() public {
        _setUpTest(siloAsset);
        uint256 amount = 1000000000;
        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        _mintAsset(amount, hazel);
        vm.prank(hazel);
        asset.approve(address(strategy), amount);

        vm.prank(hazel);
        strategy.deposit(amount, hazel);

        vm.warp(block.timestamp + 500);

        vm.prank(hazel);
        strategy.harvestRewards("");
        console.log("rewardToken", rewardToken);
        uint256 rewardBal = IERC20(rewardToken).balanceOf(address(strategy));
        assertGe(rewardBal, 0, "Fee recipient balance");

        assertEq(IERC20(rewardToken).balanceOf(address(strategy)), 0, "Hazel new share balance");
        assertGe(IERC20(rewardToken).balanceOf(hazel), 0, "Accrued Reward");
    }

    function test_getRewardTokenAddresses() public view {
        address[] memory rewardTokenAddresses = strategy.getRewardTokenAddresses();
        assertEq(rewardTokenAddresses.length, 1);
        assertEq(rewardTokenAddresses[0], rewardToken);
    }

    function test_getAvailableAssetsForWithdrawal() public {
        uint256 amount = 100 ether;
        assertEq(strategy.getAvailableAssetsForWithdrawal(), 0);
        _mintAsset(amount, hazel);

        vm.startPrank(hazel);
        asset.approve(address(strategy), amount);
        strategy.deposit(amount, hazel);
        assertEq(strategy.getAvailableAssetsForWithdrawal(), strategy.convertToAssets(strategy.totalSupply()));
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
        assertApproxEqAbs(balanceOfUnderlaying(collateralTokenBal()), amount, 0.000001 ether);
        vm.stopPrank();

        vm.startPrank(admin);
        strategy.retireStrategy();
        assertEq(collateralTokenBal(), 0);
        vm.stopPrank();
    }

    function test_totalAssets() public {
        deal(address(asset), hazel, defaultAmount);
        vm.startPrank(hazel);
        asset.approve(address(strategy), defaultAmount);
        strategy.deposit(defaultAmount, hazel);
        vm.stopPrank();
        assertEq(strategy.totalAssets() > 0, true);
        assertEq(strategy.totalAssets(), strategy.convertToAssets(strategy.totalSupply()), "Total supply converted");
    }

    function _mintAsset(uint256 amount_, address to_) internal {
        deal(address(asset), to_, amount_);
    }

    function balanceOfUnderlaying(uint256 shares) public view returns (uint256) {
        uint256 bal = strategy.balanceOfUnderlying(shares);
        console.log("bal", bal);
        console.log("shares", shares);
        return bal;
    }

    function collateralTokenBal() public view returns (uint256) {
        IERC20 collateralToken_ = IERC20(strategy.collateralToken());
        return collateralToken_.balanceOf(address(strategy));
    }

    function inflate(uint256 amount) public {
        deal(address(WETH), address(collateralToken), IERC20(WETH).balanceOf(address(collateralToken)) + amount);
    }
}
