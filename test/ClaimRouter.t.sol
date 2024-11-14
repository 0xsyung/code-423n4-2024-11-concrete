//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockERC20} from "../test/utils/mocks/MockERC20.sol";
import {ConcreteMultiStrategyVault} from "../src/vault/ConcreteMultiStrategyVault.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strategy, VaultFees, Allocation, GraduatedFee} from "../src/interfaces/IConcreteMultiStrategyVault.sol";
import {VaultRegistry} from "../src/registries/VaultRegistry.sol";
import {IMockStrategy} from "../src/interfaces/IMockStrategy.sol";
import {Errors} from "../src/interfaces/Errors.sol";
import {MockERC4626} from "./utils/mocks/MockERC4626.sol";
import {MockERC4626Protect} from "./utils/mocks/MockERC4626Protect.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MockBeraOracle} from "./utils/mocks/MockBeraOracle.sol";
import {TokenRegistry} from "../src/registries/TokenRegistry.sol";
import {ClaimRouter, ClaimRouterEvents} from "../src/claimRouter/ClaimRouter.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {VaultFlags} from "../src/interfaces/IClaimRouter.sol";
import {IMockProtectStrategy} from "../src/interfaces/IMockProtectStrategy.sol";
import {IStrategy} from "../src/interfaces/IStrategy.sol";

contract ClaimRouterTest is Test, ClaimRouterEvents {
    using Math for uint256;

    uint8 ORACLE_QUOTE_DECIMALS = 8;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLUEPRINT_ROLE = keccak256("BLUEPRINT_ROLE");
    GraduatedFee[] zeroFees;

    address treasury = address(0x1111);
    address feeRecipient = address(0x2222);
    address[] blueprints = [address(0x3333)];
    address admin = address(0x4444);

    MockERC20 fakeETH;
    MockERC20 fakeBTC;
    MockERC20 fakeUSDC;

    VaultRegistry vaultRegistry;

    address implementation;
    bytes32 vaultImplId;

    ConcreteMultiStrategyVault ethVault1;
    ConcreteMultiStrategyVault ethVault2;
    ConcreteMultiStrategyVault ethVault3;
    ConcreteMultiStrategyVault btcVault;
    ConcreteMultiStrategyVault usdcVault;

    MockBeraOracle oracle;
    string fETHfUSDPair = "FETH/FUSDC";
    string fBTCfUSDPair = "FBTC/FUSDC";
    string[] currencyPairs = [fETHfUSDPair, fBTCfUSDPair];
    address[] tokenCascade;
    int256 BTCPrice = int256(65000 * 10 ** ORACLE_QUOTE_DECIMALS);
    int256 ETHPrice = int256(4000 * 10 ** ORACLE_QUOTE_DECIMALS);

    TokenRegistry tokenRegistry;

    ClaimRouter claimRouter;

    function setUp() public {
        vaultRegistry = new VaultRegistry(admin);
        fakeETH = new MockERC20("FakeETH", "FETH", 18);
        fakeBTC = new MockERC20("FakeBTC", "FBTC", 18);
        fakeUSDC = new MockERC20("FakeUSDC", "FUSDC", 6);
        implementation = address(new ConcreteMultiStrategyVault());
        vaultImplId = keccak256(abi.encode(implementation));

        zeroFees.push(GraduatedFee({lowerBound: 0, upperBound: 10000, fee: 0}));

        ethVault1 = _createVault(fakeETH);
        ethVault2 = _createVault(fakeETH);
        ethVault3 = _createVault(fakeETH);
        btcVault = _createVault(fakeBTC);
        usdcVault = _createVault(fakeUSDC);

        //OraclePlug and TokenRegistry setup

        oracle = new MockBeraOracle();
        oracle.addCurrencyPairs(currencyPairs);

        tokenRegistry = new TokenRegistry(admin, treasury);
        _setOraclePrices(ETHPrice, BTCPrice);

        //ClaimRouter setup

        tokenCascade.push(address(fakeUSDC));
        tokenCascade.push(address(fakeETH));

        claimRouter = new ClaimRouter(admin, address(vaultRegistry), address(tokenRegistry), blueprints, tokenCascade);
    }

    function test_ProperDeployment() public view {
        address[] memory vaults = vaultRegistry.getVaultsByToken(address(fakeETH));
        assertEq(vaults[0], address(ethVault1), "Vault 1");
        assertEq(vaults.length, 3, "Vaults length");

        assertEq(address(claimRouter.vaultRegistry()), address(vaultRegistry), "VaultRegistry");
        address tokenAddress = claimRouter.tokenCascade(0);
        assertEq(tokenAddress, address(fakeUSDC), "Token 1");
    }

    function testfail_ShouldRevertIfDeployClaimRouterWithInvalidVaultRegistry() public {
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidVaultRegistry.selector);
        vm.expectRevert(encodedError);
        new ClaimRouter(admin, address(0), address(tokenRegistry), blueprints, tokenCascade);
    }

    function testfail_ShouldRevertIfDeployClaimRouterWithInvalidTokenRegistry() public {
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidTokenRegistry.selector);
        vm.expectRevert(encodedError);
        new ClaimRouter(admin, address(vaultRegistry), address(0), blueprints, tokenCascade);
    }

    function testfail_ShouldRevertIfDeployClaimRouterWithInvalidTokenCascade() public {
        address[] memory newTokenCascade = new address[](2);
        newTokenCascade[0] = address(0);
        newTokenCascade[1] = address(fakeETH);
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidAssetAddress.selector);
        vm.expectRevert(encodedError);
        new ClaimRouter(admin, address(vaultRegistry), address(tokenRegistry), blueprints, newTokenCascade);
    }

    function test_ShouldSetVaultRegistry() public {
        vm.prank(admin);
        claimRouter.setVaultRegistry(address(vaultRegistry));
        assertEq(address(claimRouter.vaultRegistry()), address(vaultRegistry), "VaultRegistry");
    }

    function testfail_ShouldRevertSetVaultRegistryIfCallerNotOwner() public {
        bytes memory encodedError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            address(this),
            DEFAULT_ADMIN_ROLE
        );
        vm.expectRevert(encodedError);
        claimRouter.setVaultRegistry(address(vaultRegistry));
    }

    function testfail_ShouldRevertIfVaultRegistryIsZero() public {
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidVaultRegistry.selector);
        vm.expectRevert(encodedError);
        vm.prank(admin);
        claimRouter.setVaultRegistry(address(0));
    }

    function test_ShouldSetTokenCascade() public {
        address[] memory newTokenCascade = new address[](2);
        newTokenCascade[0] = address(0x1);
        newTokenCascade[1] = address(fakeETH);
        vm.prank(admin);
        claimRouter.setTokenCascade(newTokenCascade);
        address tokenAddress1 = claimRouter.tokenCascade(0);
        address tokenAddress2 = claimRouter.tokenCascade(1);
        assertEq(tokenAddress1, address(0x1), "Token 1");
        assertEq(tokenAddress2, address(fakeETH), "Token 2");
    }

    function testfail_ShouldRevertSetTokenCascadeIfCallerNotOwner() public {
        bytes memory encodedError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            address(this),
            DEFAULT_ADMIN_ROLE
        );
        vm.expectRevert(encodedError);
        claimRouter.setTokenCascade(tokenCascade);
    }

    function testfail_ShouldRevertIfTokenCascadeHasZeroValue() public {
        address[] memory newTokenCascade = new address[](2);
        newTokenCascade[0] = address(0);
        newTokenCascade[1] = address(fakeETH);
        vm.prank(admin);
        bytes memory encodedError = abi.encodeWithSelector(Errors.InvalidAssetAddress.selector);
        vm.expectRevert(encodedError);
        claimRouter.setTokenCascade(newTokenCascade);
    }
    ///@notice Only one vault with a protect strategy

    function test_ShoudSelectVaultWithProtectStrategyWithBalance() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        address strategy = _addStrategy(fakeETH, ethVault1);
        // vm.prank(admin);
        fakeETH.mint(strategy, amount);

        assertEq(MockERC4626Protect(strategy).getAvailableAssetsForWithdrawal(), amount, "Balance");
        vm.expectEmit();
        emit ClaimRouterEvents.ClaimRequested(strategy, amount, IMockProtectStrategy(strategy).asset(), blueprints[0]);

        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Two vaults with a protect strategy, only one with enough balance
    function test_ShoudSelectVaultWithProtectStrategyWithBalanceFroManyOptions() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        address strategy2 = _addStrategy(fakeETH, ethVault2);
        // vm.prank(admin);
        fakeETH.mint(strategy1, amount / 2);
        fakeETH.mint(strategy2, amount);

        assertEq(MockERC4626Protect(strategy1).getAvailableAssetsForWithdrawal(), amount / 2, "Balance 1");

        assertEq(MockERC4626Protect(strategy2).getAvailableAssetsForWithdrawal(), amount, "Balance 2");
        vm.expectEmit();
        emit ClaimRouterEvents.ClaimRequested(
            strategy2,
            amount,
            IMockProtectStrategy(strategy2).asset(),
            blueprints[0]
        );
        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Two vaults with a protect strategy, the first one with enough in the vault, the second one with enough in the protect strategy. Picks the second one
    function test_ShoudSelectProtectionOverVault() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[0].strategy);
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        address strategy2 = _addStrategy(fakeETH, ethVault2);
        // vm.prank(admin);
        fakeETH.mint(strategy1, amount / 2);
        fakeETH.mint(strategy2, amount);
        fakeETH.mint(strategy, amount);

        assertEq(MockERC4626Protect(strategy1).getAvailableAssetsForWithdrawal(), amount / 2, "Balance 1");

        assertEq(MockERC4626Protect(strategy2).getAvailableAssetsForWithdrawal(), amount, "Balance 2");
        vm.expectEmit();
        emit ClaimRouterEvents.ClaimRequested(
            strategy2,
            amount,
            IMockProtectStrategy(strategy2).asset(),
            blueprints[0]
        );

        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Only one vault with a protect strategy with enough in the vault
    function test_ShoudSelectProtectionIfVaultHasEnoughBalance() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        Strategy[] memory strats = ethVault1.getStrategies();
        address strategy = address(strats[0].strategy);
        address strategy1 = _addStrategy(fakeETH, ethVault1);

        fakeETH.mint(strategy1, amount / 2);
        fakeETH.mint(strategy, amount);

        assertEq(MockERC4626Protect(strategy1).getAvailableAssetsForWithdrawal(), amount / 2, "Balance 1");

        vm.expectEmit();
        emit ClaimRouterEvents.ClaimRequested(
            strategy1,
            amount,
            IMockProtectStrategy(strategy1).asset(),
            blueprints[0]
        );

        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Two vaults with a protect strategy, both of them with enough in the vault but not in the stragies, should pick the first one
    function test_ShoudSelectTheFirstVaultToFulfilCriteria() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        Strategy[] memory stratsV1 = ethVault1.getStrategies();
        address strategyV1 = address(stratsV1[0].strategy);
        address strategy1 = _addStrategy(fakeETH, ethVault1);

        fakeETH.mint(strategy1, amount / 2);
        fakeETH.mint(strategyV1, amount);

        Strategy[] memory stratsV2 = ethVault2.getStrategies();
        address strategyV2 = address(stratsV2[0].strategy);
        address strategy2 = _addStrategy(fakeETH, ethVault2);

        fakeETH.mint(strategy2, amount / 2);
        fakeETH.mint(strategyV2, amount);

        vm.expectEmit();
        emit ClaimRouterEvents.ClaimRequested(
            strategy1,
            amount,
            IMockProtectStrategy(strategy1).asset(),
            blueprints[0]
        );

        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Can't find a vault with a protect strategy with enough balance in the
    ///requested token so it looks for a vault using the first token of the token cascade
    function test_ShoudMoveToTheFirstElementOfTheTokenCascade() public {
        uint256 amount = 1 ether;
        uint256 amountInUsdc = 4000 * 1e6;
        uint256 amountInBtc = 1 ether;
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeUSDC, usdcVault);
        fakeUSDC.mint(strategy1, amountInUsdc);

        //we add a protect strategy to the vault with enough balance
        address strategy2 = _addStrategy(fakeBTC, btcVault);
        fakeBTC.mint(strategy2, amountInBtc);

        vm.expectEmit();
        emit ClaimRouterEvents.ClaimRequested(
            strategy1,
            amountInUsdc,
            IMockProtectStrategy(strategy1).asset(),
            blueprints[0]
        );

        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Two vaults with a protect strategy, both of them with enough in the stragies, should pick the one with less yield
    function test_ShoudSelectStrategyWithLessYield() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).setHighWatermark(100);
        fakeETH.mint(strategy1, amount + amount / 2);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).setHighWatermark(99);

        fakeETH.mint(strategy2, amount);

        vm.expectEmit(true, true, true, false);
        emit ClaimRouterEvents.ClaimRequested(
            strategy2,
            amount,
            IMockProtectStrategy(strategy2).asset(),
            blueprints[0]
        );
        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Two vaults with a protect strategy, both of them with enough in the stragies, should pick the one with less yield
    function test_ShoudSelectStrategyWithLessYieldPriorizingEnoughBalanceInStrat() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        Strategy[] memory stratsV1 = ethVault1.getStrategies();
        address strategyV1 = address(stratsV1[0].strategy);
        address strategy1 = _addStrategy(fakeETH, ethVault1);

        fakeETH.mint(strategy1, amount / 2);
        fakeETH.mint(strategyV1, amount);
        IMockProtectStrategy(strategy1).setHighWatermark(80);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).setHighWatermark(99);

        fakeETH.mint(strategy2, amount);

        vm.expectEmit(true, true, true, false);
        emit ClaimRouterEvents.ClaimRequested(
            strategy2,
            amount,
            IMockProtectStrategy(strategy2).asset(),
            blueprints[0]
        );
        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    ///@notice Two vaults with a protect strategy, both of them with enough in the stragies, should pick the one with less yield
    function test_ShoudReturnAvaliableForProtection() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        Strategy[] memory stratsV1 = ethVault1.getStrategies();
        address strategyV1 = address(stratsV1[0].strategy);

        fakeETH.mint(strategyV1, amount);

        address strategy2 = _addStrategy(fakeETH, ethVault2);

        fakeETH.mint(strategy2, amount);
        uint256 avaliable1 = claimRouter.getTokenTotalAvaliableForProtection(address(fakeETH));
        //we only consider vaults with protect strategies
        assertEq(avaliable1, amount, "Avaliable one vault");
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        fakeETH.mint(strategy1, amount / 2);
        uint256 avaliable2 = claimRouter.getTokenTotalAvaliableForProtection(address(fakeETH));
        //we only consider vaults with protect strategies
        assertEq(avaliable2, amount * 2 + amount / 2, "Avaliable two vaults");
    }

    function test_ShoudSelectVaultithLessYield() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance
        Strategy[] memory stratsV1 = ethVault1.getStrategies();
        address strategyV1 = address(stratsV1[0].strategy);
        address strategy1 = _addStrategy(fakeETH, ethVault1);

        fakeETH.mint(strategy1, amount / 2);
        fakeETH.mint(strategyV1, amount);
        IMockProtectStrategy(strategy1).setHighWatermark(80);

        Strategy[] memory stratsV2 = ethVault2.getStrategies();
        address strategyV2 = address(stratsV2[0].strategy);
        address strategy2 = _addStrategy(fakeETH, ethVault2);

        fakeETH.mint(strategy2, amount / 2);
        fakeETH.mint(strategyV2, amount);
        IMockProtectStrategy(strategy2).setHighWatermark(100);
        vm.expectEmit(true, true, true, false);
        emit ClaimRouterEvents.ClaimRequested(
            strategy1,
            amount,
            IMockProtectStrategy(strategy1).asset(),
            blueprints[0]
        );
        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    function testfail_ShoudRevertIfProtectStrategyNotFound() public {
        uint256 amount = 1000 ether;
        bytes memory encodedError = abi.encodeWithSelector(Errors.NoProtectionStrategiesFound.selector);
        vm.expectRevert(encodedError);
        vm.prank(blueprints[0]);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    function testfail_ShoudRevertIfCallerIsNotTheBlueprints() public {
        uint256 amount = 1000 ether;
        bytes memory encodedError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            address(this),
            BLUEPRINT_ROLE
        );
        vm.expectRevert(encodedError);
        claimRouter.requestToken(VaultFlags.BUFFER, address(fakeETH), amount, payable(blueprints[0]));
    }

    function test_ShouldDistributeRewardsBaseOnDebt(
        uint256 amount1,
        uint256 amount2,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 3);
        vm.assume(amount2 <= type(uint256).max / 3);
        vm.assume(amount3 <= type(uint256).max / 3);
        uint256 totalAmount = amount1 + amount2 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).updateBorrowDebt(amount2);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        claimRouter.addRewards(address(fakeETH), amountToBeSent, blueprints[0]);

        uint256 sent1 = amountToBeSent.mulDiv(amount1, totalAmount, Math.Rounding.Floor);
        assertEq(fakeETH.balanceOf(strategy1), sent1, "Balance 1");

        uint256 sent2 = amountToBeSent.mulDiv(amount2, totalAmount, Math.Rounding.Floor);
        assertEq(fakeETH.balanceOf(strategy2), sent2, "Balance 2");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - (sent1 + sent2), "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");

        vm.stopPrank();
    }

    function test_ShouldDistributeRewardsCorrectlyIfThereIsOnlyOneVault(
        uint256 amount1,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max);
        vm.assume(amount1 > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        claimRouter.addRewards(address(fakeETH), amountToBeSent, blueprints[0]);

        assertEq(fakeETH.balanceOf(strategy1), amountToBeSent, "Balance 1");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");

        vm.stopPrank();
    }

    function test_ShouldDistributeRewardsBaseOnDebtIgnoringVaultsWithoutProtectStratMiddle(
        uint256 amount1,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 2);
        vm.assume(amount3 <= type(uint256).max / 2);
        uint256 totalAmount = amount1 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        claimRouter.addRewards(address(fakeETH), amountToBeSent, blueprints[0]);

        uint256 sent1 = amountToBeSent.mulDiv(amount1, totalAmount, Math.Rounding.Floor);
        assertEq(fakeETH.balanceOf(strategy1), sent1, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - sent1, "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");

        vm.stopPrank();
    }

    function test_ShouldDistributeRewardsBaseOnDebtIgnoringVaultsWithoutProtectStratLast(
        uint256 amount1,
        uint256 amount2,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 2);
        vm.assume(amount2 <= type(uint256).max / 2);
        uint256 totalAmount = amount1 + amount2;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).updateBorrowDebt(amount2);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        claimRouter.addRewards(address(fakeETH), amountToBeSent, blueprints[0]);

        uint256 sent1 = amountToBeSent.mulDiv(amount1, totalAmount, Math.Rounding.Floor);
        assertEq(fakeETH.balanceOf(strategy1), sent1, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy2), amountToBeSent - sent1, "Balance 2");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");

        vm.stopPrank();
    }

    function test_ShouldEmitRewardEvents(
        uint256 amount1,
        uint256 amount2,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 3 && amount1 > 0);
        vm.assume(amount2 <= type(uint256).max / 3 && amount2 > 0);
        vm.assume(amount3 <= type(uint256).max / 3 && amount3 > 0);
        uint256 totalAmount = amount1 + amount2 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).updateBorrowDebt(amount2);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        uint256 sent1 = amountToBeSent.mulDiv(amount1, totalAmount, Math.Rounding.Floor);
        uint256 sent2 = amountToBeSent.mulDiv(amount2, totalAmount, Math.Rounding.Floor);
        uint256 sent3 = amountToBeSent.mulDiv(amount3, totalAmount, Math.Rounding.Floor);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        vm.expectEmit();
        emit RewardAdded(strategy1, sent1);

        vm.expectEmit();
        emit RewardAdded(strategy2, sent2);

        vm.expectEmit();
        emit RewardAdded(strategy3, sent3);

        if (amountToBeSent > sent1 + sent2 + sent3) {
            vm.expectEmit();
            emit DustCleaned(strategy3, amountToBeSent - (sent1 + sent2 + sent3));
        }

        claimRouter.addRewards(address(fakeETH), amountToBeSent, blueprints[0]);

        assertEq(fakeETH.balanceOf(strategy1), sent1, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy2), sent2, "Balance 2");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - (sent1 + sent2), "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");
        vm.stopPrank();
    }

    function test_ShouldEmitOnlyRepaymentEventsWhenRepaymentIsLessThanDebt(
        uint256 amount1,
        uint256 amount2,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        // uint256 amount1 = 3;
        // uint256 amount2 = 3;
        // uint256 amount3 = 3;
        // uint256 amountToBeSent = 3;
        vm.assume(amount1 <= type(uint256).max / 3 && amount1 > 0);
        vm.assume(amount2 <= type(uint256).max / 3 && amount2 > 0);
        vm.assume(amount3 <= type(uint256).max / 3 && amount3 > 0);
        uint256 totalAmount = amount1 + amount2 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0 && amountToBeSent <= totalAmount);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).updateBorrowDebt(amount2);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        uint256 sent1 = amountToBeSent.mulDiv(amount1, totalAmount, Math.Rounding.Floor);
        uint256 sent2 = amountToBeSent.mulDiv(amount2, totalAmount, Math.Rounding.Floor);
        uint256 sent3 = amountToBeSent.mulDiv(amount3, totalAmount, Math.Rounding.Floor);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        vm.expectEmit();
        emit Repayment(strategy1, sent1);

        vm.expectEmit();
        emit Repayment(strategy2, sent2);

        vm.expectEmit();
        emit Repayment(strategy3, sent3);

        if (amountToBeSent > (sent1 + sent2 + sent3)) {
            vm.expectEmit();
            emit DustCleaned(strategy3, amountToBeSent - (sent1 + sent2 + sent3));
        }

        claimRouter.repay(address(fakeETH), amountToBeSent, blueprints[0]);

        assertEq(fakeETH.balanceOf(strategy1), sent1, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy2), sent2, "Balance 2");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - (sent1 + sent2), "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");
        vm.stopPrank();
    }

    function test_ShouldEmitRepaymentAndRewardEventsWhenRepaymentIsMoreThanDebt(
        uint256 amount1,
        uint256 amount2,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 3 && amount1 > 0);
        vm.assume(amount2 <= type(uint256).max / 3 && amount2 > 0);
        vm.assume(amount3 <= type(uint256).max / 3 && amount3 > 0);
        uint256 totalAmount = amount1 + amount2 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > totalAmount);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy2 = _addStrategy(fakeETH, ethVault2);
        IMockProtectStrategy(strategy2).updateBorrowDebt(amount2);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        uint256 sent1 = amountToBeSent.mulDiv(amount1, totalAmount, Math.Rounding.Floor);
        uint256 sent2 = amountToBeSent.mulDiv(amount2, totalAmount, Math.Rounding.Floor);
        uint256 sent3 = amountToBeSent.mulDiv(amount3, totalAmount, Math.Rounding.Floor);
        vm.assume(sent1 + sent2 + sent3 < amountToBeSent);
        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);

        if (sent1 > amount1) {
            vm.expectEmit();
            emit RewardAdded(strategy1, sent1 - amount1);
        }

        vm.expectEmit();
        emit Repayment(strategy1, amount1);

        if (sent2 > amount2) {
            vm.expectEmit();
            emit RewardAdded(strategy2, sent2 - amount2);
        }
        vm.expectEmit();
        emit Repayment(strategy2, amount2);

        if (sent3 > amount3) {
            vm.expectEmit();
            emit RewardAdded(strategy3, sent3 - amount3);
        }
        vm.expectEmit();
        emit Repayment(strategy3, amount3);

        if (amountToBeSent > (sent1 + sent2 + sent3)) {
            vm.expectEmit();
            emit DustCleaned(strategy3, amountToBeSent - (sent1 + sent2 + sent3));
        }

        claimRouter.repay(address(fakeETH), amountToBeSent, blueprints[0]);

        assertEq(fakeETH.balanceOf(strategy1), sent1, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy2), sent2, "Balance 2");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - (sent1 + sent2), "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");

        vm.stopPrank();
    }

    function testfail_ShouldDistributeEvenlyIfthereIsnoDebt(
        uint256 amount1,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 2);
        vm.assume(amount3 <= type(uint256).max / 2);
        uint256 totalAmount = amount1 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        // IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        // IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        claimRouter.addRewards(address(fakeETH), amountToBeSent, blueprints[0]);

        assertEq(fakeETH.balanceOf(strategy1), amountToBeSent / 2, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - amountToBeSent / 2, "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "Blueprints Balance");

        vm.stopPrank();
    }

    function testfail_ShouldDistributeRepaymentAsRewardsEvenlyIfthereIsnoDebt(
        uint256 amount1,
        uint256 amount3,
        uint256 amountToBeSent
    ) public {
        vm.assume(amount1 <= type(uint256).max / 2);
        vm.assume(amount3 <= type(uint256).max / 2);
        uint256 totalAmount = amount1 + amount3;
        vm.assume(totalAmount > 0);
        vm.assume(amountToBeSent > 0);
        fakeETH.mint(blueprints[0], amountToBeSent);
        //we add a protect strategy to the vault with enough balance
        address strategy1 = _addStrategy(fakeETH, ethVault1);
        // IMockProtectStrategy(strategy1).updateBorrowDebt(amount1);

        address strategy3 = _addStrategy(fakeETH, ethVault3);
        // IMockProtectStrategy(strategy3).updateBorrowDebt(amount3);

        vm.startPrank(blueprints[0]);
        fakeETH.approve(address(claimRouter), amountToBeSent);
        claimRouter.repay(address(fakeETH), amountToBeSent, blueprints[0]);

        assertEq(fakeETH.balanceOf(strategy1), amountToBeSent / 2, "Balance 1");

        assertEq(fakeETH.balanceOf(strategy3), amountToBeSent - amountToBeSent / 2, "Balance 3");

        assertEq(fakeETH.balanceOf(blueprints[0]), 0, "blueprints[0] Balance");

        vm.stopPrank();
    }

    function testfail_ShouldRevertIfThereIsNoStrat() public {
        uint256 amount = 1000 ether;
        //we add a protect strategy to the vault with enough balance

        bytes memory encodedError = abi.encodeWithSelector(Errors.NoProtectionStrategiesFound.selector);
        vm.expectRevert(encodedError);
        vm.prank(blueprints[0]);
        claimRouter.repay(address(fakeETH), amount, blueprints[0]);
    }

    function testfail_ShouldRevertIfThereIsTheAmountSentIsZero() public {
        uint256 amount = 0;
        //we add a protect strategy to the vault with enough balance
        _addStrategy(fakeETH, ethVault1);

        bytes memory encodedError = abi.encodeWithSelector(Errors.ZeroAmount.selector);
        vm.expectRevert(encodedError);
        vm.prank(blueprints[0]);
        claimRouter.repay(address(fakeETH), amount, blueprints[0]);
    }

    function testfail_ShouldRevertIfTheCallerIsNotTheBlueprint() public {
        uint256 amount = 100 ether;
        //we add a protect strategy to the vault with enough balance
        _addStrategy(fakeETH, ethVault1);

        bytes memory encodedError = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            address(this),
            BLUEPRINT_ROLE
        );
        vm.expectRevert(encodedError);
        claimRouter.repay(address(fakeETH), amount, blueprints[0]);

        vm.expectRevert(encodedError);
        claimRouter.addRewards(address(fakeETH), amount, blueprints[0]);
    }

    function _createVault(ERC20 asset) internal returns (ConcreteMultiStrategyVault) {
        string memory symbol = asset.symbol();

        ConcreteMultiStrategyVault newVault = ConcreteMultiStrategyVault(Clones.clone(implementation));
        Strategy[] memory newStrategy = new Strategy[](1);
        newStrategy[0] = Strategy({
            strategy: new MockERC4626(asset, string.concat("Mock ", symbol, " Shares"), string.concat("S", symbol)),
            allocation: Allocation({index: 0, amount: 3333})
        });

        address[] memory vaults = vaultRegistry.getVaultsByToken(address(fakeETH));
        newVault.initialize(
            ERC20(address(asset)),
            string.concat("Vault ", symbol, "Shares"),
            string.concat("V", symbol, Strings.toString(vaults.length)),
            newStrategy,
            feeRecipient,
            VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0, performanceFee: zeroFees}),
            type(uint256).max,
            admin
        );
        vm.prank(admin);
        vaultRegistry.addVault(address(newVault), vaultImplId);

        return newVault;
    }

    function _addStrategy(ERC20 asset, ConcreteMultiStrategyVault vault) internal returns (address) {
        string memory symbol = asset.symbol();
        Strategy memory newStrategy = Strategy({
            strategy: IStrategy(
                address(
                    new MockERC4626Protect(
                        asset,
                        string.concat("Mock ", symbol, " P Shares"),
                        string.concat("P", symbol)
                    )
                )
            ),
            allocation: Allocation({index: 0, amount: 3333})
        });
        vm.prank(admin);
        vault.addStrategy(0, false, newStrategy);
        return address(newStrategy.strategy);
    }

    function _setOraclePrices(int256 ETHPrice_, int256 BTCPrice_) public {
        // set prices for the oracle
        oracle.setPriceDecimalsAndTimestamp("FETH/FUSDC", ETHPrice_, ORACLE_QUOTE_DECIMALS, 1);
        oracle.setPriceDecimalsAndTimestamp("FBTC/FUSDC", BTCPrice_, ORACLE_QUOTE_DECIMALS, 1);

        // register the tokens with the TokenRegistry
        vm.prank(admin);
        tokenRegistry.registerToken(
            address(fakeETH), // token Address
            false, // is Reward
            address(oracle), // oracleAddr_,
            ORACLE_QUOTE_DECIMALS, // oracleDecimals_,
            fETHfUSDPair
        ); // oraclePair_
        vm.prank(admin);
        tokenRegistry.registerToken(
            address(fakeBTC), // token Address
            false, // is Reward
            address(oracle), // oracleAddr_,
            ORACLE_QUOTE_DECIMALS, // oracleDecimals_,
            fBTCfUSDPair
        ); // oraclePair_
    }
}
