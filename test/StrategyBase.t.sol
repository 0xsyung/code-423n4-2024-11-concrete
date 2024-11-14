//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../src/strategies/StrategyBase.sol";
import {ExampleStrategyBaseImplementation} from "./utils/examples/ExampleStrategyBaseImplementation.sol";
import {MockERC20} from "../test/utils/mocks/MockERC20.sol";

contract StrategyBaseTest is Test {
    using Math for uint256;

    MockERC20 baseAsset;
    MockERC20 reward1;
    MockERC20 reward2;
    MockERC20 reward3;
    MockERC20 reward4;
    RewardToken[] public rewardTokens;

    ExampleStrategyBaseImplementation strategy;
    ExampleStrategyBaseImplementation strategyForFailures;

    address feeRecipient = address(0x1111);
    address jimmy = address(0x2222);
    address hazel = address(0x3333);
    address admin = address(0x4444);

    function setUp() public {
        vm.label(jimmy, "Jimmy");
        vm.label(hazel, "Hazel");
        vm.label(admin, "Admin");
        vm.label(feeRecipient, "FeeRecipient");

        baseAsset = new MockERC20("BaseAsset", "BA", 18);
        reward1 = new MockERC20("Reward1", "R1", 18);
        reward2 = new MockERC20("Reward2", "R2", 18);
        reward3 = new MockERC20("Reward3", "R3", 18);
        rewardTokens.push(RewardToken({token: reward1, fee: 1000, accumulatedFeeAccounted: 0}));
        rewardTokens.push(RewardToken({token: reward2, fee: 1000, accumulatedFeeAccounted: 0}));
        rewardTokens.push(RewardToken({token: reward3, fee: 1000, accumulatedFeeAccounted: 0}));

        strategy = new ExampleStrategyBaseImplementation(
            baseAsset,
            "StrategyBase",
            "SBA",
            feeRecipient,
            type(uint256).max,
            admin,
            rewardTokens,
            admin
        );
    }

    function test_ProperDeployment() public view {
        assertEq(strategy.owner(), admin);
        assertEq(strategy.feeRecipient(), feeRecipient);
        assertEq(strategy.depositLimit(), type(uint256).max);
    }

    function testFail_InitWithImproperRewardTokenAddress() public {
        RewardToken[] memory _rewardTokens = new RewardToken[](4);
        _rewardTokens[0] = RewardToken({token: reward1, fee: 1000, accumulatedFeeAccounted: 0});
        _rewardTokens[1] = RewardToken({token: reward2, fee: 1000, accumulatedFeeAccounted: 0});
        _rewardTokens[2] = RewardToken({token: reward4, fee: 1000, accumulatedFeeAccounted: 0});
        strategyForFailures = new ExampleStrategyBaseImplementation(
            baseAsset,
            "StrategyBase",
            "SBA",
            feeRecipient,
            type(uint256).max,
            admin,
            _rewardTokens,
            admin
        );
    }

    function testFail_initWithImproperFeeAccounted() public {
        RewardToken[] memory _rewardTokens = new RewardToken[](1);
        _rewardTokens[0] = RewardToken({token: reward1, fee: 1000, accumulatedFeeAccounted: 100});
        strategyForFailures = new ExampleStrategyBaseImplementation(
            baseAsset,
            "StrategyBase",
            "SBA",
            feeRecipient,
            type(uint256).max,
            admin,
            _rewardTokens,
            admin
        );
    }

    function testFail_initWithInvalidFeeRecipient() public {
        strategyForFailures = new ExampleStrategyBaseImplementation(
            baseAsset,
            "StrategyBase",
            "SBA",
            address(0),
            type(uint256).max,
            admin,
            rewardTokens,
            admin
        );
    }

    function test_addRewardToken() public {
        RewardToken[] memory _rewardTokens = strategy.getRewardTokens();
        assertEq(_rewardTokens.length, 3);
        reward4 = new MockERC20("Reward4", "R4", 18);
        vm.prank(admin);
        strategy.addRewardToken(RewardToken({token: reward4, fee: 1000, accumulatedFeeAccounted: 0}));
        _rewardTokens = strategy.getRewardTokens();
        assertEq(_rewardTokens.length, 4);
    }

    function testFail_addRewardTokenZeroAddress() public {
        vm.prank(admin);
        strategy.addRewardToken(RewardToken({token: reward4, fee: 1000, accumulatedFeeAccounted: 0}));
    }

    function testFail_addRewardTokenTokenAlreadyApproved() public {
        vm.prank(admin);
        strategy.addRewardToken(RewardToken({token: reward1, fee: 1000, accumulatedFeeAccounted: 0}));
    }

    function testFail_addRewardTokenaccumulatedFeeAccountedZero() public {
        reward4 = new MockERC20("Reward4", "R4", 18);
        vm.prank(admin);
        strategy.addRewardToken(RewardToken({token: reward4, fee: 1000, accumulatedFeeAccounted: 100}));
    }

    function test_removeRewardToken() public {
        vm.prank(admin);
        strategy.removeRewardToken(rewardTokens[0]);
        RewardToken[] memory _rewardTokens = strategy.getRewardTokens();
        assertEq(_rewardTokens.length, 2);
    }

    function testFail_removeRewardTokenNotApproved() public {
        vm.prank(admin);
        strategy.removeRewardToken(RewardToken({token: reward4, fee: 1000, accumulatedFeeAccounted: 0}));
    }

    function test_modifyRewardFee() public {
        vm.prank(admin);
        strategy.modifyRewardFeeForRewardToken(5000, rewardTokens[0]);

        RewardToken[] memory _rewardTokens = strategy.getRewardTokens();
        assertEq(_rewardTokens[0].fee, 5000);
    }

    function testFail_modifyRewardFeeTokenNotApproved() public {
        vm.prank(admin);
        strategy.modifyRewardFeeForRewardToken(
            5000,
            RewardToken({token: reward4, fee: 1000, accumulatedFeeAccounted: 0})
        );
    }

    function test_setDepositLimit() public {
        vm.prank(admin);
        strategy.setDepositLimit(1000);

        assertEq(strategy.depositLimit(), 1000);
    }

    function test_setFeeRecipient() public {
        vm.startPrank(admin);
        strategy.setFeeRecipient(jimmy);
        vm.stopPrank();

        assertEq(strategy.feeRecipient(), jimmy);
    }

    function test_setMaxDeposit() public {
        vm.startPrank(admin);
        strategy.setDepositLimit(1000);
        vm.stopPrank();

        assertEq(strategy.depositLimit(), 1000);
    }

    function test_addRewardTokenBeforeWitdrawl() public returns (uint256 shares) {
        uint256 amount = 10 ether;
        baseAsset.mint(admin, amount);
        vm.prank(admin);
        baseAsset.approve(address(strategy), amount);
        vm.prank(admin);
        shares = strategy.deposit(amount, admin);

        assertEq(reward1.balanceOf(address(strategy)), 0, "Reward1 balance after deposit");
        assertEq(reward2.balanceOf(address(strategy)), 0, "Reward2 balance after deposit");
        assertEq(reward3.balanceOf(address(strategy)), 0, "Reward3 balance after deposit");

        vm.prank(admin);
        strategy.withdraw(amount, admin, admin);

        assertEq(reward1.balanceOf(address(strategy)), 20000000, "Reward1 balance after withdraw");
        assertEq(reward2.balanceOf(address(strategy)), 20000000, "Reward2 balance after withdraw");
    }

    function test_harvestRewards() public returns (uint256 shares) {
        uint256 amount = 10 ether;
        baseAsset.mint(admin, amount);
        vm.prank(admin);
        baseAsset.approve(address(strategy), amount);
        vm.prank(admin);
        shares = strategy.deposit(amount, admin);

        assertEq(reward1.balanceOf(address(strategy)), 0, "Reward1 balance after deposi 0");
        assertEq(reward2.balanceOf(address(strategy)), 0, "Reward2 balance after deposit 0");
        assertEq(reward3.balanceOf(address(strategy)), 0, "Reward3 balance after deposit 0");

        vm.prank(admin);
        strategy.withdraw(amount, admin, admin);

        assertEq(reward1.balanceOf(address(strategy)), 20000000, "Reward1 balance after withdraw");
        assertEq(reward2.balanceOf(address(strategy)), 20000000, "Reward2 balance after withdraw");

        vm.prank(admin);
        strategy.harvestRewards("");

        //Calculating the fee before transfering out the rewards
        assertEq(reward1.balanceOf(admin), 36000000, "Reward1 balance after harvest");
        assertEq(reward2.balanceOf(admin), 36000000, "Reward2 balance after harvest");
        assertEq(reward3.balanceOf(admin), 0, "Reward3 balance after harvest");

        RewardToken[] memory rewards = strategy.getRewardTokens();

        assertEq(rewards[0].accumulatedFeeAccounted, 4000000, "reward1 acumulated fee");
        assertEq(rewards[1].accumulatedFeeAccounted, 4000000, "reward2 acumulated fee");
        assertEq(rewards[2].accumulatedFeeAccounted, 0, "reward3 acumulated fee");
    }
}
