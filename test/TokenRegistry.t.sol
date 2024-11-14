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

import {TokenRegistry, TokenRegistryEvents} from "../src/registries/TokenRegistry.sol";

contract TokenRegistryTest is Test, TokenRegistryEvents {
    using Math for uint256;

    TokenRegistry tokenRegistry;
    address treasury = address(0x3333);
    address admin = address(0x4444);
    address hazel = address(0x5555);
    // Token
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("MockToken", "MKT", 18);
        tokenRegistry = new TokenRegistry(admin, treasury);
    }

    function test_tokenRegistryDeployed() public view {
        assertEq(address(tokenRegistry.owner()), admin);
        assertEq(tokenRegistry.getTreasury(), treasury);
    }

    function testFail_tokenRegistryDeployedInvalidTreasury() public {
        new TokenRegistry(admin, address(0));
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidTreasuryAddress.selector);
        vm.expectRevert(encodedError);
    }

    function test_registerToken() public {
        bool isReward = true;
        address oracleAddr = address(0x6666);
        uint8 oracleDecimals = 8;
        string memory pair = "ASSET/STABLE";
        OracleInformation memory oracleInfo = OracleInformation(oracleAddr, oracleDecimals, pair);
        vm.startPrank(admin);
        vm.expectEmit(false, true, true, true);
        emit TokenRegistryEvents.TokenRegistered(address(token), isReward, oracleInfo);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, oracleDecimals, pair);
        vm.stopPrank();
        // get oracle
        OracleInformation memory oracle = tokenRegistry.getOracle(address(token));
        assertEq(oracle.addr, oracleAddr);
        assertEq(oracle.decimals, oracleDecimals);
        assertEq(oracle.pair, pair);
        // check whether token is registered. Assert True that it is registered
        assertEq(tokenRegistry.isRegistered(address(token)), true, "Token is not registered");
        // check whether token is reward. Assert True that it is reward
        assertEq(tokenRegistry.isRewardToken(address(token)), true, "Token is not reward");
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        assertEq(tokenRegistry.getTokens(), tokens, "Tokens array is not equal to the expected array");
    }

    function testFail_registerTokenUnauthorized() public {
        bool isReward = true;
        address oracleAddr = address(0x6666);
        uint8 oracleDecimals = 8;
        vm.prank(hazel);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, oracleDecimals, "ASSET/STABLE");
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function testFail_registerTokenAlreadyRegistered() public {
        bool isReward = true;
        address oracleAddr = address(0x6666);
        uint8 decimals = 8;
        string memory pair = "ASSET/STABLE";
        vm.prank(admin);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, decimals, pair);
        vm.prank(admin);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, decimals, pair);
        bytes memory encodedError = abi.encodeWithSelector(Errors.TokenAlreadyRegistered.selector, address(token));
        vm.expectRevert(encodedError);
    }

    function test_removeToken() public {
        bool isReward = true;
        address oracleAddr = address(0x6666);
        uint8 oracleDecimals = 8;
        string memory pair = "ASSET/STABLE";
        vm.startPrank(admin);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, oracleDecimals, pair);
        vm.expectEmit(false, true, true, true, address(tokenRegistry));
        emit TokenRegistryEvents.TokenRemoved(address(token));
        tokenRegistry.removeToken(address(token));
        vm.stopPrank();
        // check whether token is registered. Assert False that it is not registered
        assertEq(tokenRegistry.isRegistered(address(token)), false, "Token is registered");
        // check whether token is reward. Assert False that it is not reward
        assertEq(tokenRegistry.isRewardToken(address(token)), false, "Token is reward");
        address[] memory tokens = new address[](0);
        assertEq(tokenRegistry.getTokens(), tokens, "Tokens array is not equal to the expected array");
    }

    function testFail_removeTokenUnauthorized() public {
        vm.prank(hazel);
        tokenRegistry.removeToken(address(token));
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_unregisterToken() public {
        bool isReward = true;
        address oracleAddr = address(0x6666);
        uint8 oracleDecimals = 8;
        string memory pair = "ASSET/STABLE";
        vm.startPrank(admin);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, oracleDecimals, pair);
        vm.expectEmit(false, true, true, true, address(tokenRegistry));
        emit TokenRegistryEvents.TokenUnregistered(address(token));
        tokenRegistry.unregisterToken(address(token));
        vm.stopPrank();
        // check whether token is registered. Assert False that it is not registered
        assertEq(tokenRegistry.isRegistered(address(token)), false, "Token is registered");
        // check whether token is reward. Assert True that it is reward
        assertEq(tokenRegistry.isRewardToken(address(token)), true, "Token is not reward");
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        assertEq(tokenRegistry.getTokens(), tokens, "Tokens array is not equal to the expected array");
    }

    function testFail_unregisterTokenUnauthorized() public {
        vm.prank(hazel);
        tokenRegistry.unregisterToken(address(token));
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function testFail_unregisterTokenNotRegistered() public {
        vm.prank(admin);
        tokenRegistry.unregisterToken(address(token));
        bytes memory encodedError = abi.encodeWithSelector(Errors.TokenNotRegistered.selector, address(token));
        vm.expectRevert(encodedError);
    }

    function test_updateIsReward() public {
        bool isReward = true;
        address oracleAddr = address(0x6666);
        uint8 oracleDecimals = 8;
        string memory pair = "ASSET/STABLE";
        vm.startPrank(admin);
        tokenRegistry.registerToken(address(token), isReward, oracleAddr, oracleDecimals, pair);
        vm.expectEmit(false, true, true, true, address(tokenRegistry));
        emit TokenRegistryEvents.IsRewardUpdated(address(token), false);
        tokenRegistry.updateIsReward(address(token), false);
        vm.stopPrank();
        // check whether token is reward. Assert False that it is not reward
        assertEq(tokenRegistry.isRewardToken(address(token)), false, "Token is reward");
    }

    function testFail_updateIsRewardUnregisterdCannotBeReward() public {
        vm.prank(admin);
        tokenRegistry.updateIsReward(address(token), true);
        bytes memory encodedError = abi.encodeWithSelector(
            Errors.UnregisteredTokensCannotBeRewards.selector,
            address(token)
        );
        vm.expectRevert(encodedError);
    }

    function testFail_updateIsRewardUnauthorized() public {
        vm.prank(hazel);
        tokenRegistry.updateIsReward(address(token), true);
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function test_updateOracle() public {
        address oracleAddr = address(0x8888);
        uint8 oracleDecimals = 8;
        string memory pair = "ASSET/STABLE";
        vm.startPrank(admin);
        tokenRegistry.registerToken(address(token), true, address(0x6666), 8, "");
        vm.expectEmit(false, true, true, true, address(tokenRegistry));
        emit TokenRegistryEvents.OracleUpdated(address(token), oracleAddr, oracleDecimals, pair);
        tokenRegistry.updateOracle(address(token), oracleAddr, oracleDecimals, pair);
        vm.stopPrank();
        // get oracle
        OracleInformation memory oracle = tokenRegistry.getOracle(address(token));
        assertEq(oracle.addr, oracleAddr);
        assertEq(oracle.decimals, oracleDecimals);
        assertEq(oracle.pair, pair);
    }

    function testFail_updateOracleUnauthorized() public {
        vm.prank(hazel);
        tokenRegistry.updateOracle(address(token), address(0x8888), 8, "ASSET/STABLE");
        bytes memory encodedError = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hazel);
        vm.expectRevert(encodedError);
    }

    function testFail_updateOracleNotRegistered() public {
        vm.prank(admin);
        tokenRegistry.updateOracle(address(token), address(0x8888), 8, "ASSET/STABLE");
        bytes memory encodedError = abi.encodeWithSelector(Errors.TokenNotRegistered.selector, address(token));
        vm.expectRevert(encodedError);
    }

    function test_getSubsetOfTokens() public {
        address noRewardToken = address(0x7777);
        address unregisteredToken = address(0x8888);
        vm.startPrank(admin);
        tokenRegistry.registerToken(address(token), true, address(0x6666), 8, "ASSET/STABLE");
        tokenRegistry.registerToken(noRewardToken, false, address(0x6666), 8, "NOREWARD/STABLE");
        tokenRegistry.registerToken(unregisteredToken, false, address(0x6666), 8, "UNREGISTER/STABLE");
        tokenRegistry.unregisterToken(unregisteredToken);
        vm.stopPrank();
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(token);
        address[] memory registeredTokens = new address[](2);
        registeredTokens[0] = address(token);
        registeredTokens[1] = noRewardToken;
        // check getSubsetOfTokens
        assertEq(
            tokenRegistry.getSubsetOfTokens(TokenFilterTypes.isReward),
            rewardTokens,
            "Reward Tokens array is not equal to the expected array"
        );
        assertEq(
            tokenRegistry.getSubsetOfTokens(TokenFilterTypes.isRegistered),
            registeredTokens,
            "Registered Tokens array is not equal to the expected array"
        );
    }
}
