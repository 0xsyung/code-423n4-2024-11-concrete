//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockERC20} from "../test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "./utils/mocks/MockERC4626.sol";
import {CONCRETE_USD_DECIMALS, BASISPOINTS} from "../src/interfaces/Constants.sol";
import {SwapperRewards} from "../src/interfaces/DataTypes.sol";
import {Swapper, SwapperEvents} from "../src/swapper/Swapper.sol";
import {ISwapper} from "../src/interfaces/ISwapper.sol";
import {RewardManager} from "../src/managers/RewardManager.sol";
import {TokenRegistry} from "../src/registries/TokenRegistry.sol";
import {MockBeraOracle} from "./utils/mocks/MockBeraOracle.sol";
import {Errors} from "../src/interfaces/Errors.sol";

contract StrategyBaseTest is Test, SwapperEvents {
    using Math for uint256;

    uint8 ORACLE_QUOTE_DECIMALS = 8;
    uint8 USDC_DECIMALS = 6;
    uint8 ASSET_DECIMALS = 18;
    MockERC20 usdc;
    MockERC20 asset;
    MockERC20 rewardToken;
    MockERC4626 ctAsset;

    address treasury = address(0x1111);
    address admin = address(0x4444);
    address hazel = address(0x5555);

    MockBeraOracle oracle;
    string assetUSDPair = "ASSET/USDC";
    string rewardUSDPair = "REWARD/USDC";
    string[] currencyPairs = [assetUSDPair, rewardUSDPair];

    uint16 BASE_REWARD_RATE = 500;
    uint16 MAX_PROGRESSION_FACTOR = 1000;
    uint256 PROGRESSION_UPPER_BOUND = 20_000 * 10 ** USDC_DECIMALS;
    uint16 BONUS_REWARD_RATE_USER = 0;
    uint16 BONUS_REWARD_RATE_CT_TOKEN = 0;
    uint16 BONUS_REWARD_RATE_SWAP_TOKEN = 0;
    RewardManager rewardManager;

    TokenRegistry tokenRegistry;

    Swapper swapper;

    event Swapper_Swapped(
        address indexed sender,
        address ctAssetToken,
        address rewardToken,
        uint256 ctAssetAmount,
        uint256 rewardAmount
    );

    function setUp() public {
        vm.label(admin, "admin");
        vm.label(hazel, "hazel");
        // start prank with admin
        vm.startPrank(admin);

        usdc = new MockERC20("Circle USD", "USDC", USDC_DECIMALS);
        asset = new MockERC20("Asset", "ASSET", ASSET_DECIMALS);
        rewardToken = new MockERC20("Reward", "REWARD", ASSET_DECIMALS);
        ctAsset = new MockERC4626(IERC20(asset), "ctAsset", "ctASSET");

        oracle = new MockBeraOracle();
        oracle.addCurrencyPairs(currencyPairs);

        rewardManager = new RewardManager(
            admin,
            BASE_REWARD_RATE,
            MAX_PROGRESSION_FACTOR,
            PROGRESSION_UPPER_BOUND,
            BONUS_REWARD_RATE_USER,
            BONUS_REWARD_RATE_CT_TOKEN,
            BONUS_REWARD_RATE_SWAP_TOKEN
        );

        tokenRegistry = new TokenRegistry(admin, treasury);

        swapper = new Swapper(admin, address(tokenRegistry), address(rewardManager), treasury);

        // stop prank
        vm.stopPrank();
    }

    function test_deploySwapper() public view {
        assertEq(swapper.owner(), admin, "Owner");
        assertEq(swapper.getTreasury(), address(treasury), "Token Registry");
        assertEq(swapper.getTokenRegistry(), address(tokenRegistry), "Token Registry");
        assertEq(swapper.getRewardManager(), address(rewardManager), "Reward Manager");
    }

    function testFail_deploySwapperWithZeroAddressTreasury() public {
        vm.prank(admin);
        address zeroAddress = address(0);
        new Swapper(admin, address(tokenRegistry), address(rewardManager), zeroAddress);
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidTreasuryAddress.selector);
        vm.expectRevert(encodedError);
    }

    function test_swapTokensForReward() public {
        uint256 rewardAmountInTreasury = 100_000_000 * 10 ** ASSET_DECIMALS;
        uint256 initialAssetAmount = 1_000 * 10 ** ASSET_DECIMALS;
        int256 rewardPrice = int256(500 * 10 ** ORACLE_QUOTE_DECIMALS);
        int256 assetPrice = int256(22 * 10 ** ORACLE_QUOTE_DECIMALS);
        // mint some reward tokens to the treasury
        rewardToken.mint(treasury, rewardAmountInTreasury);
        // Hazel to receive ctAssets from the ctAsset Vault
        vm.startPrank(hazel);
        asset.mint(hazel, initialAssetAmount);
        asset.approve(address(ctAsset), initialAssetAmount);
        ctAsset.deposit(initialAssetAmount, hazel);
        vm.stopPrank();

        // set prices for the oracle
        _setOraclePrices(assetPrice, rewardPrice);

        // Hazel wants to swap half of his ctAsset belongings
        uint256 hazelCtAssetAmount = ctAsset.balanceOf(hazel);
        uint256 ctAssetAmountToBeSwapped = hazelCtAssetAmount / 2;
        // treasury to approve the spending of reward tokens
        vm.prank(treasury);
        rewardToken.approve(address(swapper), rewardAmountInTreasury);
        vm.prank(hazel);
        ctAsset.approve(address(swapper), ctAssetAmountToBeSwapped);

        // calculate the expected answer
        uint256 assetAmountFromCtAssetAmount = ctAsset.convertToAssets(ctAssetAmountToBeSwapped);
        uint256 totalRewardTokenAmount = _getExpectedRewardTokenAmount(
            assetAmountFromCtAssetAmount,
            assetPrice,
            rewardPrice
        );

        vm.startPrank(hazel);
        vm.expectEmit(false, true, true, true, address(swapper));
        emit SwapperEvents.Swapped(
            hazel,
            address(ctAsset),
            address(rewardToken),
            ctAssetAmountToBeSwapped,
            totalRewardTokenAmount
        );
        // create the swap
        swapper.swapTokensForReward(address(ctAsset), address(rewardToken), ctAssetAmountToBeSwapped);

        vm.stopPrank();
        // assert that the balance of reward tokens in the treasury is correct
        assertEq(rewardToken.balanceOf(hazel), totalRewardTokenAmount, "Reward Token balance Of Hazel");
    }

    // test error when there is not sufficient for withdrawal
    function testFail_swapTokensForRewardUnavailable() public {
        uint256 rewardAmountInTreasury = 1 * 10 ** ASSET_DECIMALS;
        uint256 initialAssetAmount = 1_000 * 10 ** ASSET_DECIMALS;
        int256 rewardPrice = int256(500 * 10 ** ORACLE_QUOTE_DECIMALS);
        int256 assetPrice = int256(22 * 10 ** ORACLE_QUOTE_DECIMALS);

        // mint some reward tokens to the treasury
        rewardToken.mint(treasury, rewardAmountInTreasury);

        // Hazel to receive ctAssets from the ctAsset Vault
        vm.startPrank(hazel);
        asset.mint(hazel, initialAssetAmount);
        asset.approve(address(ctAsset), initialAssetAmount);
        ctAsset.deposit(initialAssetAmount, hazel);
        vm.stopPrank();

        // set prices for the oracle
        _setOraclePrices(assetPrice, rewardPrice);

        // treasury to approve the spending of reward tokens
        vm.prank(treasury);
        rewardToken.approve(address(swapper), rewardAmountInTreasury);
        vm.prank(hazel);
        ctAsset.approve(address(swapper), ctAsset.balanceOf(hazel));

        // calculate the expected answer
        uint256 assetAmountFromCtAssetAmount = ctAsset.convertToAssets(ctAsset.balanceOf(hazel));
        uint256 totalRewardTokenAmount = _getExpectedRewardTokenAmount(
            assetAmountFromCtAssetAmount,
            assetPrice,
            rewardPrice
        );

        // create the swap
        vm.prank(hazel);
        swapper.swapTokensForReward(address(ctAsset), address(rewardToken), ctAsset.balanceOf(hazel));

        // expect revert with error NotAvailableForWithdrawal(address token, uint256 amount);
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.NotAvailableForWithdrawal.selector,
            address(rewardToken),
            totalRewardTokenAmount
        );

        vm.expectRevert(encodedError);
    }

    // check setters
    function test_setRewardManager() public {
        vm.startPrank(admin);
        address newRewardManager = address(0x1234);
        vm.expectEmit(false, true, true, true, address(swapper));
        emit SwapperEvents.RewardManagerUpdated(newRewardManager);
        swapper.setRewardManager(newRewardManager);
        vm.stopPrank();
        assertEq(swapper.getRewardManager(), newRewardManager, "Reward Manager Updated");
    }

    function test_disableTokenForSwap() public {
        vm.startPrank(admin);
        address token = address(0x1234);
        assertEq(swapper.tokenAvailableForWithdrawal(token), true, "Token Available");
        bool disableSwap = true;
        swapper.disableTokenForSwap(token, disableSwap);
        vm.stopPrank();
        assertEq(swapper.tokenAvailableForWithdrawal(token), false, "Token Disabled");
    }

    function testFail_RevertSetRewardManager() public {
        address newRewardManager = address(0x1234);
        vm.prank(hazel);
        swapper.setRewardManager(newRewardManager);
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function testFail_RevertDisableTokenForSwap() public {
        address token = address(0x1234);
        bool disableSwap = true;
        vm.prank(hazel);
        swapper.disableTokenForSwap(token, disableSwap);
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_amountAvailableForWithdrawal() public {
        uint256 rewardAmountInTreasury = 1 * 10 ** ASSET_DECIMALS;
        rewardToken.mint(treasury, rewardAmountInTreasury);
        assertEq(
            swapper.amountAvailableForWithdrawal(address(rewardToken), rewardAmountInTreasury),
            true,
            "Amount Available"
        );
        assertEq(
            swapper.amountAvailableForWithdrawal(address(rewardToken), rewardAmountInTreasury + 1),
            false,
            "Amount Not Available"
        );
        vm.prank(admin);
        swapper.disableTokenForSwap(address(rewardToken), true);
        assertEq(
            swapper.amountAvailableForWithdrawal(address(rewardToken), rewardAmountInTreasury),
            false,
            "Amount Not Available"
        );
    }

    function test_previewSwapTokensForReward() public {
        uint256 ctAssetAmount = 2 * 10 ** (ASSET_DECIMALS + 9);
        int256 rewardPrice = int256(500 * 10 ** ORACLE_QUOTE_DECIMALS);
        int256 assetPrice = int256(22 * 10 ** ORACLE_QUOTE_DECIMALS);

        // set prices for the oracle
        _setOraclePrices(assetPrice, rewardPrice);

        // calculate the expected answer
        uint256 assetAmountFromCtAssetAmount = ctAsset.convertToAssets(ctAssetAmount);
        uint256 expectedRewardTokenAmount = _getExpectedRewardTokenAmount(
            assetAmountFromCtAssetAmount,
            assetPrice,
            rewardPrice
        );

        // create the swap
        vm.prank(hazel);
        (uint256 actualRewardAmount, bool availableForWithdrawal, bool isRewardToken) = swapper
            .previewSwapTokensForReward(address(ctAsset), address(rewardToken), ctAssetAmount);

        // assert that the balance of reward tokens in the treasury is correct
        assertEq(actualRewardAmount, expectedRewardTokenAmount, "Reward Token balance Of Hazel");
        assertEq(availableForWithdrawal, true, "Reward Token Available For Withdrawal");
        assertEq(isRewardToken, true, "Reward Token is Reward Token");

        // set the reward token to be unavailable for withdrawal
        vm.prank(admin);
        swapper.disableTokenForSwap(address(rewardToken), true);
        (, availableForWithdrawal, ) = swapper.previewSwapTokensForReward(
            address(ctAsset),
            address(rewardToken),
            ctAssetAmount
        );

        assertEq(availableForWithdrawal, false, "Chosen Token Not Available For Withdrawal");

        // set the reward token to be not a reward token
        vm.prank(admin);
        tokenRegistry.updateIsReward(address(rewardToken), false);
        (, , isRewardToken) = swapper.previewSwapTokensForReward(address(ctAsset), address(rewardToken), ctAssetAmount);
        assertEq(isRewardToken, false, "Chosen Token is not a listed as reward on Token Registry");
    }

    // Auxilliary functions /////////////////////////////////////

    function _getExpectedRewardTokenAmount(
        uint256 ctAssetAmount,
        int256 assetPrice,
        int256 rewardPrice
    ) public view returns (uint256) {
        uint256 assetAmountInStable = (((ctAssetAmount * uint256(assetPrice)) / 10 ** ORACLE_QUOTE_DECIMALS) *
            10 ** CONCRETE_USD_DECIMALS) / 10 ** ASSET_DECIMALS;
        uint256 rewardrateInBasisPoints = BASE_REWARD_RATE +
            ((assetAmountInStable * MAX_PROGRESSION_FACTOR) / PROGRESSION_UPPER_BOUND);
        uint256 rewardInStables = ((assetAmountInStable * rewardrateInBasisPoints) / BASISPOINTS);
        uint256 totalRewardTokenAmountInStables = assetAmountInStable + rewardInStables;

        // translate that back to reward token amount
        uint256 totalRewardTokenAmount = ((((totalRewardTokenAmountInStables * 10 ** ASSET_DECIMALS) /
            uint256(rewardPrice)) * 10 ** ORACLE_QUOTE_DECIMALS) / 10 ** CONCRETE_USD_DECIMALS);
        return totalRewardTokenAmount;
    }

    function _setOraclePrices(int256 assetPrice, int256 rewardPrice) public {
        // set prices for the oracle
        oracle.setPriceDecimalsAndTimestamp("ASSET/USDC", assetPrice, ORACLE_QUOTE_DECIMALS, 1);
        oracle.setPriceDecimalsAndTimestamp("REWARD/USDC", rewardPrice, ORACLE_QUOTE_DECIMALS, 1);

        // register the tokens with the TokenRegistry
        vm.prank(admin);
        tokenRegistry.registerToken(
            address(asset), // token Address
            false, // is Reward
            address(oracle), // oracleAddr_,
            ORACLE_QUOTE_DECIMALS, // oracleDecimals_,
            assetUSDPair
        ); // oraclePair_
        vm.prank(admin);
        tokenRegistry.registerToken(
            address(rewardToken), // token Address
            true, // is Reward
            address(oracle), // oracleAddr_,
            ORACLE_QUOTE_DECIMALS, // oracleDecimals_,
            rewardUSDPair
        ); // oraclePair_
    }
}

// mint some reward tokens to the treasury
// reward.mint(treasury, 1_000_000 * 10**ASSET_DECIMALS);
