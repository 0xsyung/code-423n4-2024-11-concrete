//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockERC20} from "../test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "./utils/mocks/MockERC4626.sol";
import {TokenInformation, OracleInformation, TokenFilterTypes} from "../src/interfaces/DataTypes.sol";
import {Errors} from "../src/interfaces/Errors.sol";

import {RewardManager, RewardManagerEvents} from "../src/managers/RewardManager.sol";

contract TokenRegistryTest is Test, RewardManagerEvents {
    using Math for uint256;

    RewardManager public rewardManager;
    address admin = address(0x3333);
    uint16 BASE_REWARD_RATE = 1000;
    uint16 MAX_PROGRESSION_FACTOR = 1000;
    uint256 PROGRESSION_UPPER_BOUND = 100_000;
    uint16 BONUS_REWARD_RATE_USER = 1000;
    uint16 BONUS_REWARD_RATE_CT_TOKEN = 1000;
    uint16 BONUS_REWARD_RATE_SWAP_TOKEN = 1000;

    function setUp() public {}

    function test_constructor() public {
        rewardManager = _deployRewardManager();
        assertEq(rewardManager.owner(), admin, "Owner should be set correctly");
        assertEq(rewardManager.getSwapperBaseRewardrate(), BASE_REWARD_RATE, "Wrong base reward rate");
        assertEq(rewardManager.getMaxProgressionFactor(), MAX_PROGRESSION_FACTOR, "Wrong max progression factor");
        assertEq(
            rewardManager.getSwapperProgressionUpperBound(),
            PROGRESSION_UPPER_BOUND,
            "Wrong progression upper bound"
        );
        assertEq(
            rewardManager.getSwapperBonusRewardrateForUser(),
            BONUS_REWARD_RATE_USER,
            "Wrong bonus reward rate for user"
        );
        assertEq(
            rewardManager.getSwapperBonusRewardrateForCtToken(),
            BONUS_REWARD_RATE_CT_TOKEN,
            "Wrong bonus reward rate for ct token"
        );
        assertEq(
            rewardManager.getSwapperBonusRewardrateForSwapToken(),
            BONUS_REWARD_RATE_SWAP_TOKEN,
            "Wrong bonus reward rate for swap token"
        );
    }

    function testFail_constructorBadSwapperBonusRewardrateForSwapToken() public {
        new RewardManager(
            admin,
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            10001
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateSwapToken.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_constructorBadSwapperBonusRewardrateCtToken() public {
        new RewardManager(
            admin,
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            10001,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateCtToken.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_constructorBadSwapperBonusRewardrateUser() public {
        new RewardManager(
            admin,
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            10001,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateUser.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_constructorBadMaxProgressionFactor() public {
        new RewardManager(
            admin,
            BASE_REWARD_RATE,
            10001,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperMaxProgressionFactor.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_constructorBadBaseRewardrate() public {
        new RewardManager(
            admin,
            10001,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBaseRewardrate.selector);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperRewards() public {
        rewardManager = new RewardManager(
            admin,
            BASE_REWARD_RATE + 1,
            MAX_PROGRESSION_FACTOR + 1,
            PROGRESSION_UPPER_BOUND + 1,
            BONUS_REWARD_RATE_USER + 1,
            BONUS_REWARD_RATE_CT_TOKEN + 1,
            BONUS_REWARD_RATE_SWAP_TOKEN + 1
        );
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperRewardsUpdated(
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        rewardManager.setSwapperRewards(
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        vm.stopPrank();
        assertEq(rewardManager.getSwapperBaseRewardrate(), BASE_REWARD_RATE, "Wrong base reward rate");
        assertEq(rewardManager.getMaxProgressionFactor(), MAX_PROGRESSION_FACTOR, "Wrong max progression factor");
        assertEq(
            rewardManager.getSwapperProgressionUpperBound(),
            PROGRESSION_UPPER_BOUND,
            "Wrong progression upper bound"
        );
        assertEq(
            rewardManager.getSwapperBonusRewardrateForUser(),
            BONUS_REWARD_RATE_USER,
            "Wrong bonus reward rate for user"
        );
        assertEq(
            rewardManager.getSwapperBonusRewardrateForCtToken(),
            BONUS_REWARD_RATE_CT_TOKEN,
            "Wrong bonus reward rate for ct token"
        );
        assertEq(
            rewardManager.getSwapperBonusRewardrateForSwapToken(),
            BONUS_REWARD_RATE_SWAP_TOKEN,
            "Wrong bonus reward rate for swap token"
        );
    }

    function testFail_setSwapperRewardsBadBonusRewardrateForSwapToken() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperRewards(
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            10001
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateSwapToken.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperRewardsBadBonusRewardrateCtToken() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperRewards(
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            10001,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateCtToken.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperRewardsBadBonusRewardrateUser() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperRewards(
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            10001,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateUser.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperRewardsBadMaxProgressionFactor() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperRewards(
            BASE_REWARD_RATE,
            10001,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperMaxProgressionFactor.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperRewardsBadBaseRewardrate() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperRewards(
            10001,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBaseRewardrate.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperRewardsUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperRewards(
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperBaseRewardrate() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperBaseRewardrateUpdated(BASE_REWARD_RATE + 1);
        rewardManager.setSwapperBaseRewardrate(BASE_REWARD_RATE + 1);
        vm.stopPrank();
        assertEq(rewardManager.getSwapperBaseRewardrate(), BASE_REWARD_RATE + 1, "Wrong base reward rate");
    }

    function testFail_setSwapperBaseRewardrateInvalid() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperBaseRewardrate(10001);
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBaseRewardrate.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperBaseRewardrateUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperBaseRewardrate(BASE_REWARD_RATE + 1);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperMaxProgressionFactor() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperMaxProgressionFactorUpdated(MAX_PROGRESSION_FACTOR + 1);
        rewardManager.setSwapperMaxProgressionFactor(MAX_PROGRESSION_FACTOR + 1);
        vm.stopPrank();
        assertEq(rewardManager.getMaxProgressionFactor(), MAX_PROGRESSION_FACTOR + 1, "Wrong max progression factor");
    }

    function testFail_setSwapperMaxProgressionFactorInvalid() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperMaxProgressionFactor(10001);
        bytes memory encodedError = abi.encodePacked(Errors.SwapperMaxProgressionFactor.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperMaxProgressionFactorUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperMaxProgressionFactor(MAX_PROGRESSION_FACTOR + 1);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperProgressionUpperBound() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperProgressionUpperBoundUpdated(PROGRESSION_UPPER_BOUND + 1);
        rewardManager.setSwapperProgressionUpperBound(PROGRESSION_UPPER_BOUND + 1);
        vm.stopPrank();
        assertEq(
            rewardManager.getSwapperProgressionUpperBound(),
            PROGRESSION_UPPER_BOUND + 1,
            "Wrong progression upper bound"
        );
    }

    function testFail_setSwapperProgressionUpperBoundUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperProgressionUpperBound(PROGRESSION_UPPER_BOUND + 1);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperBonusRewardrateForUser() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperBonusRewardrateForUserUpdated(BONUS_REWARD_RATE_USER + 1);
        rewardManager.setSwapperBonusRewardrateForUser(BONUS_REWARD_RATE_USER + 1);
        vm.stopPrank();
        assertEq(
            rewardManager.getSwapperBonusRewardrateForUser(),
            BONUS_REWARD_RATE_USER + 1,
            "Wrong bonus reward rate for user"
        );
    }

    function testFail_setSwapperBonusRewardrateForUserInvalid() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperBonusRewardrateForUser(10001);
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateUser.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperBonusRewardrateForUserUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperBonusRewardrateForUser(BONUS_REWARD_RATE_USER + 1);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperBonusRewardrateForCtToken() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperBonusRewardrateForCtTokenUpdated(BONUS_REWARD_RATE_CT_TOKEN + 1);
        rewardManager.setSwapperBonusRewardrateForCtToken(BONUS_REWARD_RATE_CT_TOKEN + 1);
        vm.stopPrank();
        assertEq(
            rewardManager.getSwapperBonusRewardrateForCtToken(),
            BONUS_REWARD_RATE_CT_TOKEN + 1,
            "Wrong bonus reward rate for ct token"
        );
    }

    function testFail_setSwapperBonusRewardrateForCtTokenInvalid() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperBonusRewardrateForCtToken(10001);
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateCtToken.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperBonusRewardrateForCtTokenUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperBonusRewardrateForCtToken(BONUS_REWARD_RATE_CT_TOKEN + 1);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_setSwapperBonusRewardrateForSwapToken() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperBonusRewardrateForSwapTokenUpdated(BONUS_REWARD_RATE_SWAP_TOKEN + 1);
        rewardManager.setSwapperBonusRewardrateForSwapToken(BONUS_REWARD_RATE_SWAP_TOKEN + 1);
        vm.stopPrank();
        assertEq(
            rewardManager.getSwapperBonusRewardrateForSwapToken(),
            BONUS_REWARD_RATE_SWAP_TOKEN + 1,
            "Wrong bonus reward rate for swap token"
        );
    }

    function testFail_setSwapperBonusRewardrateForSwapTokenInvalid() public {
        rewardManager = _deployRewardManager();
        vm.startPrank(admin);
        rewardManager.setSwapperBonusRewardrateForSwapToken(10001);
        bytes memory encodedError = abi.encodePacked(Errors.SwapperBonusRewardrateSwapToken.selector);
        vm.expectRevert(encodedError);
    }

    function testFail_setSwapperBonusRewardrateForSwapTokenUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.setSwapperBonusRewardrateForSwapToken(BONUS_REWARD_RATE_SWAP_TOKEN + 1);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_enableSwapperBonusRateForUser() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.prank(admin);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        vm.prank(admin);
        assertEq(rewardManager.swapperBonusRateForUser(hazel), true, "Wrong bonus rate for user");
    }

    function testFail_enableSwapperBonusRateForUserUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function testFail_enableSwapperBonusRateForUserInvalidUserAddress() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0);
        vm.startPrank(admin);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        bytes memory encodedError = abi.encodePacked(Errors.InvalidUserAddress.selector);
        vm.expectRevert(encodedError);
    }

    function test_enableSwapperBonusRateForRewardToken() public {
        rewardManager = _deployRewardManager();
        address user = address(0x4444);
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperBonusRateForRewardTokenEnabled(user, true);
        rewardManager.enableSwapperBonusRateForRewardToken(user, true);
        vm.stopPrank();
        assertEq(rewardManager.swapperBonusRateForRewardToken(user), true, "Wrong bonus rate for reward token");
    }

    function testFail_enableSwapperBonusRateForRewardTokenUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.enableSwapperBonusRateForRewardToken(hazel, true);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_enableSwapperBonusRateForCtToken() public {
        rewardManager = _deployRewardManager();
        address user = address(0x4444);
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true, address(rewardManager));
        emit RewardManagerEvents.SwapperBonusRateForCtTokenEnabled(user, true);
        rewardManager.enableSwapperBonusRateForCtToken(user, true);
        vm.stopPrank();
        assertEq(rewardManager.swapperBonusRateForCtToken(user), true, "Wrong bonus rate for ct token");
    }

    function testFail_enableSwapperBonusRateForCtTokenUnauthorized() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.startPrank(hazel);
        rewardManager.enableSwapperBonusRateForCtToken(hazel, true);
        bytes memory encodedError = abi.encodePacked(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_swapperBonusRateForUser() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        vm.prank(admin);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        vm.prank(hazel);
        assertEq(rewardManager.swapperBonusRateForUser(hazel), true, "Wrong bonus rate for user");
    }

    function testFail_swapperBonusRateForUserInvalidUserAddress() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        address bob = address(0x5555);
        vm.prank(admin);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        vm.prank(bob);
        rewardManager.swapperBonusRateForUser(hazel);
        bytes memory encodedError = abi.encodePacked(Errors.InvalidUserAddress.selector);
        vm.expectRevert(encodedError);
    }

    function test_quoteSwapperRewardrateSmallCtAssetAmount() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        address rewardToken = address(0x5555);
        address ctAssetToken = address(0x6666);
        vm.startPrank(admin);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        rewardManager.enableSwapperBonusRateForRewardToken(rewardToken, true);
        rewardManager.enableSwapperBonusRateForCtToken(ctAssetToken, true);
        vm.stopPrank();
        uint256 ctAssetAmountInStables = PROGRESSION_UPPER_BOUND / 2;
        uint256 rewardRate = BASE_REWARD_RATE;
        rewardRate += ctAssetAmountInStables.mulDiv(
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            Math.Rounding.Floor
        );
        rewardRate += BONUS_REWARD_RATE_USER;
        rewardRate += BONUS_REWARD_RATE_CT_TOKEN;
        rewardRate += BONUS_REWARD_RATE_SWAP_TOKEN;

        assertEq(
            rewardRate,
            rewardManager.quoteSwapperRewardrate(hazel, ctAssetToken, rewardToken, ctAssetAmountInStables),
            "Wrong reward rate"
        );
    }

    function test_quoteSwapperRewardrateLargeCtAssetAmount() public {
        rewardManager = _deployRewardManager();
        address hazel = address(0x4444);
        address rewardToken = address(0x5555);
        address ctAssetToken = address(0x6666);
        vm.startPrank(admin);
        rewardManager.enableSwapperBonusRateForUser(hazel, true);
        rewardManager.enableSwapperBonusRateForRewardToken(rewardToken, true);
        rewardManager.enableSwapperBonusRateForCtToken(ctAssetToken, true);
        vm.stopPrank();
        uint256 ctAssetAmountInStables = PROGRESSION_UPPER_BOUND * 2;
        uint256 rewardRate = BASE_REWARD_RATE;
        rewardRate += MAX_PROGRESSION_FACTOR;
        rewardRate += BONUS_REWARD_RATE_USER;
        rewardRate += BONUS_REWARD_RATE_CT_TOKEN;
        rewardRate += BONUS_REWARD_RATE_SWAP_TOKEN;

        assertEq(
            rewardRate,
            rewardManager.quoteSwapperRewardrate(hazel, ctAssetToken, rewardToken, ctAssetAmountInStables),
            "Wrong reward rate"
        );
    }

    function _deployRewardManager() internal returns (RewardManager) {
        return
            new RewardManager(
                admin,
                BASE_REWARD_RATE,
                MAX_PROGRESSION_FACTOR,
                PROGRESSION_UPPER_BOUND,
                BONUS_REWARD_RATE_USER,
                BONUS_REWARD_RATE_CT_TOKEN,
                BONUS_REWARD_RATE_SWAP_TOKEN
            );
    }
}

// function enableSwapperBonusRateForUser(address user_, bool enableBonusRate_) external onlyOwner {
//     if (user_==address(0)) revert Errors.InvalidUserAddress();
//     _swapperGetsBonusRate[user_] = enableBonusRate_;
// }

// function enableSwapperBonusRateForRewardToken(address rewardToken_, bool enableBonusRate_) external onlyOwner {
//     _swappedRewardTokenGetsBonusRate[rewardToken_] = enableBonusRate_;
// }

// function enableSwapperBonusRateForCtToken(address ctAssetToken_, bool enableBonusRate_) external onlyOwner {
//     _swappedCtTokenGetsBonusRate[ctAssetToken_] = enableBonusRate_;
// }
