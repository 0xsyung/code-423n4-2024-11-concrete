# Report

- [Report](#report)
  - [Gas Optimizations](#gas-optimizations)
    - [\[GAS-1\] Don't use `_msgSender()` if not supporting EIP-2771](#gas-1-dont-use-_msgsender-if-not-supporting-eip-2771)
    - [\[GAS-2\] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)](#gas-2-a--a--b-is-more-gas-effective-than-a--b-for-state-variables-excluding-arrays-and-mappings)
    - [\[GAS-3\] Use assembly to check for `address(0)`](#gas-3-use-assembly-to-check-for-address0)
    - [\[GAS-4\] Using bools for storage incurs overhead](#gas-4-using-bools-for-storage-incurs-overhead)
    - [\[GAS-5\] Cache array length outside of loop](#gas-5-cache-array-length-outside-of-loop)
    - [\[GAS-6\] State variables should be cached in stack variables rather than re-reading them from storage](#gas-6-state-variables-should-be-cached-in-stack-variables-rather-than-re-reading-them-from-storage)
    - [\[GAS-7\] Use calldata instead of memory for function arguments that do not get mutated](#gas-7-use-calldata-instead-of-memory-for-function-arguments-that-do-not-get-mutated)
    - [\[GAS-8\] For Operations that will not overflow, you could use unchecked](#gas-8-for-operations-that-will-not-overflow-you-could-use-unchecked)
    - [\[GAS-9\] Avoid contract existence checks by using low level calls](#gas-9-avoid-contract-existence-checks-by-using-low-level-calls)
    - [\[GAS-10\] State variables only set in the constructor should be declared `immutable`](#gas-10-state-variables-only-set-in-the-constructor-should-be-declared-immutable)
    - [\[GAS-11\] Functions guaranteed to revert when called by normal users can be marked `payable`](#gas-11-functions-guaranteed-to-revert-when-called-by-normal-users-can-be-marked-payable)
    - [\[GAS-12\] `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`)](#gas-12-i-costs-less-gas-compared-to-i-or-i--1-same-for---i-vs-i---or-i---1)
    - [\[GAS-13\] Using `private` rather than `public` for constants, saves gas](#gas-13-using-private-rather-than-public-for-constants-saves-gas)
    - [\[GAS-14\] Superfluous event fields](#gas-14-superfluous-event-fields)
    - [\[GAS-15\] Increments/decrements can be unchecked in for-loops](#gas-15-incrementsdecrements-can-be-unchecked-in-for-loops)
    - [\[GAS-16\] Use != 0 instead of \> 0 for unsigned integer comparison](#gas-16-use--0-instead-of--0-for-unsigned-integer-comparison)
    - [\[GAS-17\] `internal` functions not called by the contract should be removed](#gas-17-internal-functions-not-called-by-the-contract-should-be-removed)
  - [Non Critical Issues](#non-critical-issues)
    - [\[NC-1\] Missing checks for `address(0)` when assigning values to address state variables](#nc-1-missing-checks-for-address0-when-assigning-values-to-address-state-variables)
    - [\[NC-2\] Array indices should be referenced via `enum`s rather than via numeric literals](#nc-2-array-indices-should-be-referenced-via-enums-rather-than-via-numeric-literals)
    - [\[NC-3\] `require()` should be used instead of `assert()`](#nc-3-require-should-be-used-instead-of-assert)
    - [\[NC-4\] Constants should be in CONSTANT\_CASE](#nc-4-constants-should-be-in-constant_case)
    - [\[NC-5\] `constant`s should be defined rather than using magic numbers](#nc-5-constants-should-be-defined-rather-than-using-magic-numbers)
    - [\[NC-6\] Control structures do not follow the Solidity Style Guide](#nc-6-control-structures-do-not-follow-the-solidity-style-guide)
    - [\[NC-7\] Critical Changes Should Use Two-step Procedure](#nc-7-critical-changes-should-use-two-step-procedure)
    - [\[NC-8\] Default Visibility for constants](#nc-8-default-visibility-for-constants)
    - [\[NC-9\] Consider disabling `renounceOwnership()`](#nc-9-consider-disabling-renounceownership)
    - [\[NC-10\] Unused `error` definition](#nc-10-unused-error-definition)
    - [\[NC-11\] Event is never emitted](#nc-11-event-is-never-emitted)
    - [\[NC-12\] Events should use parameters to convey information](#nc-12-events-should-use-parameters-to-convey-information)
    - [\[NC-13\] Event missing indexed field](#nc-13-event-missing-indexed-field)
    - [\[NC-14\] Events that mark critical parameter changes should contain both the old and the new value](#nc-14-events-that-mark-critical-parameter-changes-should-contain-both-the-old-and-the-new-value)
    - [\[NC-15\] Function ordering does not follow the Solidity style guide](#nc-15-function-ordering-does-not-follow-the-solidity-style-guide)
    - [\[NC-16\] Functions should not be longer than 50 lines](#nc-16-functions-should-not-be-longer-than-50-lines)
    - [\[NC-17\] Interfaces should be defined in separate files from their usage](#nc-17-interfaces-should-be-defined-in-separate-files-from-their-usage)
    - [\[NC-18\] Lack of checks in setters](#nc-18-lack-of-checks-in-setters)
    - [\[NC-19\] Missing Event for critical parameters change](#nc-19-missing-event-for-critical-parameters-change)
    - [\[NC-20\] NatSpec is completely non-existent on functions that should have them](#nc-20-natspec-is-completely-non-existent-on-functions-that-should-have-them)
    - [\[NC-21\] Incomplete NatSpec: `@param` is missing on actually documented functions](#nc-21-incomplete-natspec-param-is-missing-on-actually-documented-functions)
    - [\[NC-22\] Incomplete NatSpec: `@return` is missing on actually documented functions](#nc-22-incomplete-natspec-return-is-missing-on-actually-documented-functions)
    - [\[NC-23\] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor](#nc-23-use-a-modifier-instead-of-a-requireif-statement-for-a-special-msgsender-actor)
    - [\[NC-24\] Consider using named mappings](#nc-24-consider-using-named-mappings)
    - [\[NC-25\] Owner can renounce while system is paused](#nc-25-owner-can-renounce-while-system-is-paused)
    - [\[NC-26\] Adding a `return` statement when the function defines a named return variable, is redundant](#nc-26-adding-a-return-statement-when-the-function-defines-a-named-return-variable-is-redundant)
    - [\[NC-27\] `require()` / `revert()` statements should have descriptive reason strings](#nc-27-requirerevertstatements-should-have-descriptive-reason-strings)
    - [\[NC-28\] Take advantage of Custom Error's return value property](#nc-28-take-advantage-of-custom-errors-return-value-property)
    - [\[NC-29\] Contract does not follow the Solidity style guide's suggested layout ordering](#nc-29-contract-does-not-follow-the-solidity-style-guides-suggested-layout-ordering)
    - [\[NC-30\] TODO Left in the code](#nc-30-todo-left-in-the-code)
    - [\[NC-31\] Use Underscores for Number Literals (add an underscore every 3 digits)](#nc-31-use-underscores-for-number-literals-add-an-underscore-every-3-digits)
    - [\[NC-32\] Internal and private variables and functions names should begin with an underscore](#nc-32-internal-and-private-variables-and-functions-names-should-begin-with-an-underscore)
    - [\[NC-33\] Event is missing `indexed` fields](#nc-33-event-is-missing-indexed-fields)
    - [\[NC-34\] `public` functions not called by the contract should be declared `external` instead](#nc-34-public-functions-not-called-by-the-contract-should-be-declared-external-instead)
    - [\[NC-35\] Variables need not be initialized to zero](#nc-35-variables-need-not-be-initialized-to-zero)
  - [Low Issues](#low-issues)
    - [\[L-1\] `approve()`/`safeApprove()` may revert if the current approval is not zero](#l-1-approvesafeapprove-may-revert-if-the-current-approval-is-not-zero)
    - [\[L-2\] Use a 2-step ownership transfer pattern](#l-2-use-a-2-step-ownership-transfer-pattern)
    - [\[L-3\] Some tokens may revert when zero value transfers are made](#l-3-some-tokens-may-revert-when-zero-value-transfers-are-made)
    - [\[L-4\] Missing checks for `address(0)` when assigning values to address state variables](#l-4-missing-checks-for-address0-when-assigning-values-to-address-state-variables)
    - [\[L-5\] `decimals()` is not a part of the ERC-20 standard](#l-5-decimals-is-not-a-part-of-the-erc-20-standard)
    - [\[L-6\] `decimals()` should be of type `uint8`](#l-6-decimals-should-be-of-type-uint8)
    - [\[L-7\] Deprecated approve() function](#l-7-deprecated-approve-function)
    - [\[L-8\] Division by zero not prevented](#l-8-division-by-zero-not-prevented)
    - [\[L-9\] Duplicate import statements](#l-9-duplicate-import-statements)
    - [\[L-10\] Empty Function Body - Consider commenting why](#l-10-empty-function-body---consider-commenting-why)
    - [\[L-11\] External call recipient may consume all transaction gas](#l-11-external-call-recipient-may-consume-all-transaction-gas)
    - [\[L-12\] Initializers could be front-run](#l-12-initializers-could-be-front-run)
    - [\[L-13\] Prevent accidentally burning tokens](#l-13-prevent-accidentally-burning-tokens)
    - [\[L-14\] Owner can renounce while system is paused](#l-14-owner-can-renounce-while-system-is-paused)
    - [\[L-15\] Possible rounding issue](#l-15-possible-rounding-issue)
    - [\[L-16\] Loss of precision](#l-16-loss-of-precision)
    - [\[L-17\] Solidity version 0.8.20+ may not work on other chains due to `PUSH0`](#l-17-solidity-version-0820-may-not-work-on-other-chains-due-to-push0)
    - [\[L-18\] Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership`](#l-18-use-ownable2steptransferownership-instead-of-ownabletransferownership)
    - [\[L-19\] `symbol()` is not a part of the ERC-20 standard](#l-19-symbol-is-not-a-part-of-the-erc-20-standard)
    - [\[L-20\] Unsafe ERC20 operation(s)](#l-20-unsafe-erc20-operations)
    - [\[L-21\] Unspecific compiler version pragma](#l-21-unspecific-compiler-version-pragma)
    - [\[L-22\] Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions](#l-22-upgradeable-contract-is-missing-a-__gap50-storage-variable-to-allow-for-new-storage-variables-in-later-versions)
    - [\[L-23\] Upgradeable contract not initialized](#l-23-upgradeable-contract-not-initialized)
    - [\[L-24\] Use `initializer` for public-facing functions only. Replace with `onlyInitializing` on internal functions](#l-24-use-initializer-for-public-facing-functions-only-replace-with-onlyinitializing-on-internal-functions)
    - [\[L-25\] A year is not always 365 days](#l-25-a-year-is-not-always-365-days)
  - [Medium Issues](#medium-issues)
    - [\[M-1\] Contracts are vulnerable to fee-on-transfer accounting-related issues](#m-1-contracts-are-vulnerable-to-fee-on-transfer-accounting-related-issues)
    - [\[M-2\] Centralization Risk for trusted owners](#m-2-centralization-risk-for-trusted-owners)
      - [Impact](#impact)
    - [\[M-3\] `increaseAllowance/decreaseAllowance` won't work on mainnet for USDT](#m-3-increaseallowancedecreaseallowance-wont-work-on-mainnet-for-usdt)
    - [\[M-4\] Unsafe use of `transfer()`/`transferFrom()`/`approve()`/ with `IERC20`](#m-4-unsafe-use-of-transfertransferfromapprove-with-ierc20)
  - [High Issues](#high-issues)
    - [\[H-1\] IERC20.approve() will revert for USDT](#h-1-ierc20approve-will-revert-for-usdt)

## Gas Optimizations

| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | Don't use `_msgSender()` if not supporting EIP-2771 | 5 |
| [GAS-2](#GAS-2) | `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings) | 19 |
| [GAS-3](#GAS-3) | Use assembly to check for `address(0)` | 37 |
| [GAS-4](#GAS-4) | Using bools for storage incurs overhead | 9 |
| [GAS-5](#GAS-5) | Cache array length outside of loop | 12 |
| [GAS-6](#GAS-6) | State variables should be cached in stack variables rather than re-reading them from storage | 5 |
| [GAS-7](#GAS-7) | Use calldata instead of memory for function arguments that do not get mutated | 19 |
| [GAS-8](#GAS-8) | For Operations that will not overflow, you could use unchecked | 290 |
| [GAS-9](#GAS-9) | Avoid contract existence checks by using low level calls | 25 |
| [GAS-10](#GAS-10) | State variables only set in the constructor should be declared `immutable` | 19 |
| [GAS-11](#GAS-11) | Functions guaranteed to revert when called by normal users can be marked `payable` | 76 |
| [GAS-12](#GAS-12) | `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`) | 43 |
| [GAS-13](#GAS-13) | Using `private` rather than `public` for constants, saves gas | 4 |
| [GAS-14](#GAS-14) | Superfluous event fields | 1 |
| [GAS-15](#GAS-15) | Increments/decrements can be unchecked in for-loops | 1 |
| [GAS-16](#GAS-16) | Use != 0 instead of > 0 for unsigned integer comparison | 13 |
| [GAS-17](#GAS-17) | `internal` functions not called by the contract should be removed | 8 |

### <a name="GAS-1"></a>[GAS-1] Don't use `_msgSender()` if not supporting EIP-2771

Use `msg.sender` if the code does not implement [EIP-2771 trusted forwarder](https://eips.ethereum.org/EIPS/eip-2771) support

*Instances (5)*:

```solidity
File: src/managers/RewardManager.sol

285:         if (!(owner() == _msgSender() || user_ == _msgSender())) revert Errors.InvalidUserAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

51:         if (claimRouter != _msgSender()) {

52:             revert ClaimRouterUnauthorizedAccount(_msgSender());

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

97:         if (protectStrategy != _msgSender()) {

98:             revert ProtectUnauthorizedAccount(_msgSender());

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-2"></a>[GAS-2] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)

This saves **16 gas per instance.**

*Instances (19)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

302:             totalSent += amountToBeSent;

350:                 data.totalBorrowDebt += IProtectStrategy(protectionStrat).getBorrowDebt();

373:                 total += currentVault.getAvailableAssetsForWithdrawal();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/RewardManager.sol

252:             rewardRate += uint256(_swapperRewards.bonusRewardrateUser);

256:             rewardRate += uint256(_swapperRewards.bonusRewardrateCtToken);

260:             rewardRate += uint256(_swapperRewards.bonusRewardrateSwapToken);

276:             rewardRate += progressionFactor;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

139:         borrowDebt += amount;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

45:                 result += 1;

85:                 result += 1;

106:             s += _numbers[i];

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/StrategyBase.sol

352:                     rewardTokens[i].accumulatedFeeAccounted += collectedFee;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

403:         shares += feeShares;

472:                 totalWithdrawn += amountToWithdraw;

518:             totalAvailable += strategy.strategy.getAvailableAssetsForWithdrawal();

578:             total += strategies[i].strategy.convertToAssets(strategies[i].strategy.balanceOf(address(this)));

875:             allotmentTotals += allocations_[i].amount;

1014:                     rewardIndex[rewardToken] += amount.mulDiv(PRECISION, totalSupply, Math.Rounding.Floor);

1043:                     totalRewardsClaimed[userAddress][rewardAddresses[i]] += rewardsToTransfer;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-3"></a>[GAS-3] Use assembly to check for `address(0)`

*Saves 6 gas per instance*

*Instances (37)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

67:         if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();

68:         if (owner == address(0)) revert InvalidDefaultAdminAddress();

74:             if (blueprint_[i] != address(0)) _grantRole(BLUEPRINT_ROLE, blueprint_[i]);

87:         if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/DeploymentManager.sol

62:         if (implementationData.implementationAddress == address(0)) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

174:         if (user_ == address(0)) revert Errors.InvalidUserAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

32:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

47:         if (vault_ == address(0)) revert VaultZeroAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

117:         if (address(aaveIncentives) == address(0)) return;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

90:         if (claimRouter_ == address(0)) revert InvalidClaimRouterAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

37:         if (addressesProvider_ == address(0)) revert ZeroAddress();

131:         if (address(incentiveController) == address(0)) return;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

50:         if (siloRepository_ == address(0)) revert ZeroAddress();

51:         if (siloIncentivesController_ == address(0)) revert ZeroAddress();

55:         if (address(silo) == address(0)) revert ZeroAddress();

92:         if (address(collateralToken) == address(0)) revert InvalidAssetAddress();

178:         if (address(siloIncentivesController) == address(0)) return;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

90:                 if (address(rewardTokens_[i].token) == address(0)) {

109:         if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();

193:         if (address(rewardToken_.token) == address(0)) {

262:         if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/OraclePlug.sol

22:         if (tokenRegistry_ == address(0)) revert Errors.InvalidTokenRegistry();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

66:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

156:         if (address(baseAsset_) == address(0)) revert InvalidAssetAddress();

167:         if (feeRecipient_ == address(0)) {

356:         if (receiver_ == address(0)) revert InvalidRecipient();

393:         if (receiver_ == address(0)) revert InvalidRecipient();

429:             if (address(withdrawalQueue) == address(0)) {

584:         if (address(withdrawalQueue) != address(0)) {

756:         if (newRecipient_ == address(0)) revert InvalidFeeRecipient();

771:         if (withdrawalQueue_ == address(0)) revert InvalidWithdrawlQueue();

772:         if (address(withdrawalQueue) != address(0)) {

825:         if (address(removedStrategy) != address(0)) emit StrategyRemoved(address(removedStrategy));

853:         if (from != address(0)) updateUserRewardsToCurrent(from);

854:         if (to != address(0)) updateUserRewardsToCurrent(to);

1060:         if (address(withdrawalQueue) == address(0)) revert QueueNotSet();

1113:         if (receiver_ == address(0)) revert InvalidRecipient();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-4"></a>[GAS-4] Using bools for storage incurs overhead

Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (9)*:

```solidity
File: src/managers/RewardManager.sol

38:     mapping(address => bool) internal _swapperGetsBonusRate;

39:     mapping(address => bool) internal _swappedRewardTokenGetsBonusRate;

40:     mapping(address => bool) internal _swappedCtTokenGetsBonusRate;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

18:     mapping(bytes32 => bool) public implementationExists;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

21:     mapping(address => bool) public vaultExists;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

22:     bool public rewardsEnabled;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

49:     mapping(address => bool) public rewardTokenApproved;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/Swapper.sol

52:     mapping(address => bool) internal _unavailableForWithdrawal;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

64:     bool public vaultIdle;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-5"></a>[GAS-5] Cache array length outside of loop

If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (12)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

273:         for (uint256 i; i < vaults.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

76:         for (uint256 i = 0; i < _requestIds.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/TokenRegistry.sol

157:         for (uint256 i = 0; i < tokens.length; ) {

169:         for (uint256 i = 0; i < tokens.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

105:         for (uint256 i; i < _numbers.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

81:         for (temp.i = 0; temp.i < temp.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

88:             for (uint256 i; i < rewardTokens_.length; ) {

326:         for (uint256 i = 0; i < rewards.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

575:         for (uint256 i; i < strategies.length; ) {

997:         for (uint256 i; i < strategies.length; ) {

1000:             for (uint256 k = 0; k < indices.length; k++) {

1009:             for (uint256 j; j < returnedRewards.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-6"></a>[GAS-6] State variables should be cached in stack variables rather than re-reading them from storage

The instances below point to the second+ access of a state variable within a function. Caching of a state variable replaces each Gwarmaccess (100 gas) with a much cheaper stack read. Other less obvious fixes/optimizations include having local memory caches of state variable structs, or having local caches of state variable contracts/addresses.

*Saves 100 gas per instance*

*Instances (5)*:

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

105:         IERC20(baseAsset_).safeIncreaseAllowance(address(silo), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

358:                 TokenHelper.attemptSafeTransfer(address(rewardAddress), _vault, netReward, false);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/Swapper.sol

95:         IERC20(rewardToken_).safeTransferFrom(address(_treasury), msg.sender, rewardAmount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

773:             if (withdrawalQueue.unfinalizedAmount() != 0) revert UnfinalizedWithdrawl(address(withdrawalQueue));

776:         emit WithdrawalQueueUpdated(address(withdrawalQueue), withdrawalQueue_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-7"></a>[GAS-7] Use calldata instead of memory for function arguments that do not get mutated

When a function with a `memory` array is called externally, the `abi.decode()` step has to use a for-loop to copy each index of the `calldata` to the `memory` index. Each iteration of this for-loop costs at least 60 gas (i.e. `60 * <mem_array>.length`). Using `calldata` directly bypasses this loop.

If the array is passed to an `internal` function which passes the array to another internal function where the array is modified and therefore `memory` is used in the `external` call, it's still more gas-efficient to use `calldata` when the `external` function uses modifiers, since the modifiers may prevent the internal functions from being called. Structs have the same overhead as an array of length one.

 *Saves 60 gas per instance*

*Instances (19)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/interfaces/IStrategy.sol

16:     function harvestRewards(bytes memory) external returns (ReturnedRewards[] memory);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IStrategy.sol)

```solidity
File: src/interfaces/ITokenRegistry.sol

20:         string memory oraclePair_

40:         string memory oraclePair_

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/ITokenRegistry.sol)

```solidity
File: src/managers/DeploymentManager.sol

42:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/VaultManager.sol

86:         ImplementationData memory implementation_

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

35:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

50:         string memory oraclePair_

97:         string memory oraclePair_

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/Aave/IAaveV3.sol

67:         address[] memory assets,

90:         address[] memory assets,

91:         uint256[] memory amounts,

92:         uint256[] memory interestRateModes,

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/IAaveV3.sol)

```solidity
File: src/strategies/StrategyBase.sol

338:         bytes memory data

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

143:         string memory shareName_,

144:         string memory shareSymbol_,

145:         Strategy[] memory strategies_,

147:         VaultFees memory fees_,

989:     function harvestRewards(bytes memory encodedData) external onlyOwner nonReentrant {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-8"></a>[GAS-8] For Operations that will not overflow, you could use unchecked

*Instances (290)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

4: import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

5: import {Errors} from "../interfaces/Errors.sol";

6: import {IClaimRouter, VaultFlags} from "../interfaces/IClaimRouter.sol";

7: import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

8: import {IProtectStrategy} from "../interfaces/IProtectStrategy.sol";

9: import {IConcreteMultiStrategyVault} from "../interfaces/IConcreteMultiStrategyVault.sol";

10: import {OraclePlug} from "../swapper/OraclePlug.sol";

11: import {IProtectStrategy} from "../interfaces/IProtectStrategy.sol";

12: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

13: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

14: import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

76:                 i++;

114:                 i++;

145:                     i++;

164:                     i++;

175:                 i++;

201:                         i++;

216:                     i++;

279:                     i++;

291:                         i++;

302:             totalSent += amountToBeSent;

311:                     i++;

317:                 emit RewardAdded(protectionStrat, amountToBeSent - stratBorrowDebt);

326:                 i++;

330:             emit DustCleaned(lastProtectionStrat, amount_ - totalSent);

332:             IERC20(tokenAddress).safeTransferFrom(userBlueprint, lastProtectionStrat, amount_ - totalSent);

349:                 data.vaultsWithProtect++;

350:                 data.totalBorrowDebt += IProtectStrategy(protectionStrat).getBorrowDebt();

353:                 i++;

373:                 total += currentVault.getAvailableAssetsForWithdrawal();

376:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/factories/VaultFactory.sol

4: import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

5: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

6: import {ConcreteMultiStrategyVault} from "../vault/ConcreteMultiStrategyVault.sol";

7: import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";

8: import {Errors} from "../interfaces/Errors.sol";

9: import {IVaultFactory} from "../interfaces/IVaultFactory.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/interfaces/DataTypes.sol

12:     string pair; // e.g. "ETH/USDC"

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/DataTypes.sol)

```solidity
File: src/interfaces/Errors.sol

4: import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/Errors.sol)

```solidity
File: src/interfaces/IConcreteMultiStrategyVault.sol

4: import {IStrategy} from "./IStrategy.sol";

25:     uint256 amount; // Represented in BPS of the amount of ETF that should go into strategy

29:     IStrategy strategy; //TODO: Create interface for real Strategy and implement here

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IConcreteMultiStrategyVault.sol)

```solidity
File: src/interfaces/IMockProtectStrategy.sol

4: import {IMockStrategy} from "./IMockStrategy.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IMockProtectStrategy.sol)

```solidity
File: src/interfaces/IMockStrategy.sol

4: import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IMockStrategy.sol)

```solidity
File: src/interfaces/IProtectStrategy.sol

4: import {IStrategy} from "./IStrategy.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IProtectStrategy.sol)

```solidity
File: src/interfaces/IStrategy.sol

4: import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IStrategy.sol)

```solidity
File: src/interfaces/ITokenRegistry.sol

4: import {OracleInformation, TokenFilterTypes} from "../interfaces/DataTypes.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/ITokenRegistry.sol)

```solidity
File: src/interfaces/IVaultDeploymentManager.sol

4: import {ImplementationData} from "./IImplementationRegistry.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IVaultDeploymentManager.sol)

```solidity
File: src/interfaces/IVaultFactory.sol

4: import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IVaultFactory.sol)

```solidity
File: src/managers/DeploymentManager.sol

5: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

6: import {VaultFactory} from "../factories/VaultFactory.sol";

7: import {ImplementationData, IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";

8: import {IVaultFactory} from "../interfaces/IVaultFactory.sol";

9: import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

10: import {IVaultDeploymentManager} from "../interfaces/IVaultDeploymentManager.sol";

11: import {Errors} from "../interfaces/Errors.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

5: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

6: import {SwapperRewards} from "../interfaces/DataTypes.sol";

7: import {BASISPOINTS} from "../interfaces/Constants.sol";

8: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

9: import {Errors} from "../interfaces/Errors.sol";

252:             rewardRate += uint256(_swapperRewards.bonusRewardrateUser);

256:             rewardRate += uint256(_swapperRewards.bonusRewardrateCtToken);

260:             rewardRate += uint256(_swapperRewards.bonusRewardrateSwapToken);

276:             rewardRate += progressionFactor;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/managers/VaultManager.sol

4: import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

6: import {IConcreteMultiStrategyVault, VaultFees, Strategy, Allocation} from "../interfaces/IConcreteMultiStrategyVault.sol";

7: import {ImplementationData, IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";

8: import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

9: import {IVaultDeploymentManager} from "../interfaces/IVaultDeploymentManager.sol";

10: import {WithdrawalQueue} from "../queue/WithdrawalQueue.sol";

56:                 i++;

70:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

6: import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

7: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

8: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

9: import {IWithdrawalQueue} from "../interfaces/IWithdrawalQueue.sol";

79:                 i++;

103:         return lastRequestId - lastFinalizedRequestId;

110:         return _requests[lastRequestId].cumulativeAmount - _requests[lastFinalizedRequestId].cumulativeAmount;

118:         WithdrawalRequest memory previousRequest = _requests[_requestId - 1];

121:             request.cumulativeAmount - previousRequest.cumulativeAmount,

135:         uint128 cumulativeAmount = lastRequest.cumulativeAmount + SafeCast.toUint128(amount);

136:         uint256 requestId = _lastRequestId + 1;

166:         WithdrawalRequest storage prevRequest = _requests[_requestId - 1];

168:         amount = request.cumulativeAmount - prevRequest.cumulativeAmount;

172:             avaliableAssets = _avaliableAssets - amount;

193:             uint256 firstRequestIdToFinalize = _lastFinalizedRequestId + 1;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

5: import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";

6: import {Errors} from "../interfaces/Errors.sol";

7: import {IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";

67:                 i++;

71:         allImplementations[indexToBeRemoved] = allImplementations[len - 1];

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

5: import {TokenInformation, OracleInformation, TokenFilterTypes} from "../interfaces/DataTypes.sol";

7: import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

8: import {Errors} from "../interfaces/Errors.sol";

9: import {ITokenRegistry} from "../interfaces/ITokenRegistry.sol";

113:             revert Errors.UnregisteredTokensCannotBeRewards(tokenAddress_); // check if token is registered

159:                 count++;

161:                 count++;

164:                 i++;

172:                 count++;

175:                 count++;

178:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

5: import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

6: import {Errors} from "../interfaces/Errors.sol";

7: import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

8: import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

97:                 if (i < length - 1) {

98:                     vaultArray_[i] = vaultArray_[length - 1];

104:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

4: import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

8: import {StrategyBase} from "../StrategyBase.sol";

9: import {ILendingPool, IAaveIncentives, IAToken, IProtocolDataProvider} from "./IAaveV3.sol";

47:             string.concat("ctAv3-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/Aave/IAaveV3.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

5: import {DataTypes} from "./DataTypes.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/IAaveV3.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

4: import {IERC20, IERC20Metadata, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

5: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

7: import {StrategyBase, RewardToken} from "../StrategyBase.sol";

8: import {IProtectStrategy} from "../../interfaces/IProtectStrategy.sol";

9: import {IConcreteMultiStrategyVault} from "../../interfaces/IConcreteMultiStrategyVault.sol";

39:             string.concat("ctPct-", metaERC20.symbol()),

70:         return totalAssets_.mulDiv(10 ** uint256(DECIMAL_OFFSET), totalSupply_, Math.Rounding.Ceil);

120:         borrowDebt -= amount;

136:             _requestFromVault(amount - balance);

139:         borrowDebt += amount;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/IRadiantV2.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

6: import {DataTypes} from "./DataTypes.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/IRadiantV2.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

4: import {IERC20, IERC20Metadata, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

5: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

7: import {StrategyBase} from "../StrategyBase.sol";

8: import {DataTypes} from "./DataTypes.sol";

9: import {IAToken, IChefIncentivesController, ILendingPoolAddressesProvider, ILendingPool} from "./IRadiantV2.sol";

53:             string.concat("ctRdV2-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

15:         result = amount * totalShares;

18:             result /= totalAmount;

36:         uint256 numerator = amount * totalShares;

39:             result = numerator / totalAmount;

45:                 result += 1;

55:         result = share * totalAmount;

58:             result /= totalShares;

76:         uint256 numerator = share * totalAmount;

79:             result = numerator / totalShares;

85:                 result += 1;

96:         value = _assetAmount * _assetPrice;

99:             value /= 10 ** _assetDecimals;

106:             s += _numbers[i];

108:                 i++;

129:         utilization = _totalBorrowAmount * _dp;

132:             utilization /= _totalDeposits;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/IBaseSiloV1.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/IBaseSiloV1.sol)

```solidity
File: src/strategies/Silo/ISiloV1.sol

4: import "./IBaseSiloV1.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/ISiloV1.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

4: import {IERC20, IERC20Metadata, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

5: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

6: import {EasyMathV2} from "./EasyMathV2.sol";

8: import {StrategyBase, RewardToken} from "../StrategyBase.sol";

9: import {ISilo, ISiloRepository, ISiloIncentivesController} from "./ISiloV1.sol";

65:                     temp.i++;

77:         temp.rewardTokenArray = new RewardToken[](temp.length + 1);

82:             temp.rewardTokenArray[temp.i + 1] = RewardToken(

88:                 temp.i++;

96:             string.concat("ctSlV1-", baseAsset_.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

4: import {ERC4626Upgradeable, IERC20, IERC20Metadata, IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

7: import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

8: import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

9: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

10: import {Errors} from "../interfaces/Errors.sol";

11: import {ReturnedRewards} from "../interfaces/IStrategy.sol";

12: import {IStrategy, ReturnedRewards} from "../interfaces/IStrategy.sol";

14: import {TokenHelper} from "@blueprint-finance/hub-and-spokes-libraries/src/libraries/TokenHelper.sol";

103:                     i++;

117:         _decimals = IERC20Metadata(address(baseAsset_)).decimals() + DECIMAL_OFFSET;

182:         return IERC20(asset()).balanceOf(address(this)) + _totalAssets();

223:         rewardTokens[_getIndex(address(rewardToken_.token))] = rewardTokens[rewardTokens.length - 1];

294:         return rewardTokens; // Return the array of configured reward tokens.

309:                 index = i; // Set the index if the token is found.

310:                 break; // Exit the loop once the token is found.

313:                 ++i;

329:                 ++i;

352:                     rewardTokens[i].accumulatedFeeAccounted += collectedFee;

353:                     netReward = claimedBalance - collectedFee;

363:                 ++i;

375:                 ++i;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

4: import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

8: import {StrategyBase} from "../StrategyBase.sol";

9: import {ICToken, ICometRewarder, RewardConfig} from "./ICompoundV3.sol";

50:             string.concat("ctCM3-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

4: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

5: import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

6: import {IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

7: import {CONCRETE_USD_DECIMALS} from "../interfaces/Constants.sol";

8: import {OracleInformation} from "../interfaces/DataTypes.sol";

9: import {ITokenRegistry} from "../interfaces/ITokenRegistry.sol";

10: import {IBeraOracle} from "../interfaces/IBeraOracle.sol";

11: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

12: import {Errors} from "../interfaces/Errors.sol";

49:             price.mulDiv(tokenAmount_, 10 ** quoteDecimals, Math.Rounding.Floor).mulDiv(

50:                 10 ** CONCRETE_USD_DECIMALS,

51:                 10 ** tokenDecimals,

79:             stableAmount_.mulDiv(10 ** tokenDecimals, 10 ** CONCRETE_USD_DECIMALS, Math.Rounding.Floor).mulDiv(

80:                 10 ** quoteDecimals,

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

5: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

6: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

7: import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

10: import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

11: import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

12: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

15: import {Errors} from "../interfaces/Errors.sol";

16: import {BASISPOINTS} from "../interfaces/Constants.sol";

17: import {SwapperRewards} from "../interfaces/DataTypes.sol";

20: import {IRewardManager} from "../interfaces/IRewardManager.sol";

21: import {ISwapper} from "../interfaces/ISwapper.sol";

24: import {OraclePlug} from "./OraclePlug.sol";

209:         return _convertFromStableToToken(rewardToken_, ctAssetAmountInStables + rewardStableAmount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

4: import {ERC4626Upgradeable, IERC20, IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

5: import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

7: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

8: import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

9: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

10: import {VaultFees, Strategy, IConcreteMultiStrategyVault, Allocation} from "../interfaces/IConcreteMultiStrategyVault.sol";

11: import {Errors} from "../interfaces/Errors.sol";

12: import {IStrategy, ReturnedRewards} from "../interfaces/IStrategy.sol";

13: import {IWithdrawalQueue} from "../interfaces/IWithdrawalQueue.sol";

14: import {MultiStrategyVaultHelper} from "../libraries/MultiStrategyVaultHelper.sol";

15: import {MAX_BASIS_POINTS} from "../utils/Constants.sol";

105:         uint256 totalFee = accruedProtocolFee() + accruedPerformanceFee();

115:                 : totalFee.mulDiv(supply, _totalAssets - totalFee, Math.Rounding.Floor);

172:         highWaterMark = 1e9; // Set the initial high water mark for performance fee calculation.

242:         shares = _convertToShares(assets_, Math.Rounding.Floor) - feeShares;

263:                     i++;

300:         uint256 feeShares = shares_.mulDiv(MAX_BASIS_POINTS, MAX_BASIS_POINTS - depositFee, Math.Rounding.Floor) -

304:         assets = _convertToAssets(shares_ + feeShares, Math.Rounding.Ceil);

326:                     i++;

362:         assets = _convertToAssets(shares_ - feeShares, Math.Rounding.Floor);

401:             ? shares.mulDiv(MAX_BASIS_POINTS, MAX_BASIS_POINTS - withdrawalFee, Math.Rounding.Floor) - shares

403:         shares += feeShares;

421:             _approve(owner_, msg.sender, allowance(owner_, msg.sender) - shares);

453:             uint256 diff = amount_ - float;

462:                     revert InsufficientFunds(strategy.strategy, diff * strategy.allocation.amount, withdrawable);

472:                 totalWithdrawn += amountToWithdraw;

474:                     i++;

478:             if (totalWithdrawn < amount_ && amount_ - totalWithdrawn <= float) {

479:                 asset_.safeTransfer(receiver_, amount_ - totalWithdrawn);

518:             totalAvailable += strategy.strategy.getAvailableAssetsForWithdrawal();

520:                 i++;

538:             uint256 calculatedRewards = (tokenRewardIndex - userRewardIndex[userAddress][rewardAddresses[i]]).mulDiv(

545:                 i++;

561:                 i++;

578:             total += strategies[i].strategy.convertToAssets(strategies[i].strategy.balanceOf(address(this)));

580:                 i++;

591:         total -= unfinalized;

601:         uint256 netAssets = assets_ -

617:         uint256 grossShares = shares_.mulDiv(MAX_BASIS_POINTS, MAX_BASIS_POINTS - fees.depositFee, Math.Rounding.Floor);

630:             ? shares.mulDiv(MAX_BASIS_POINTS, MAX_BASIS_POINTS - fees.withdrawalFee, Math.Rounding.Floor)

641:         uint256 netShares = shares_ -

658:         return (paused() || totalAssets() >= depositLimit) ? 0 : depositLimit - totalAssets();

669:         shares = assets.mulDiv(totalSupply() + 10 ** decimalOffset, totalAssets() + 1, rounding);

680:         return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** decimalOffset, rounding);

695:                     totalAssets() * (block.timestamp - feesUpdatedAt),

698:                 ) / 10000; // Normalize the fee percentage

745:         fees = newFees_; // Update the fee structure

746:         feesUpdatedAt = block.timestamp; // Record the time of the fee update

761:         feeRecipient = newRecipient_; // Update the fee recipient

778:         withdrawalQueue = IWithdrawalQueue(withdrawalQueue_); // Update the fee recipient

845:         strategies[index_] = strategies[len - 1];

875:             allotmentTotals += allocations_[i].amount;

878:                 i++;

916:                 i++;

1000:             for (uint256 k = 0; k < indices.length; k++) {

1014:                     rewardIndex[rewardToken] += amount.mulDiv(PRECISION, totalSupply, Math.Rounding.Floor);

1017:                     j++;

1021:                 i++;

1040:                 uint256 rewardsToTransfer = (tokenRewardIndex - userRewardIndex[userAddress][rewardAddresses[i]])

1043:                     totalRewardsClaimed[userAddress][rewardAddresses[i]] += rewardsToTransfer;

1049:                 i++;

1067:         uint256 max = lastCreatedId < lastFinalizedId + maxRequests ? lastCreatedId : lastFinalizedId + maxRequests;

1069:         for (uint256 i = lastFinalizedId + 1; i <= max; ) {

1077:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-9"></a>[GAS-9] Avoid contract existence checks by using low level calls

Prior to 0.8.10 the compiler inserted extra code, including `EXTCODESIZE` (**100 gas**), to check for contract existence for external function calls. In more recent solidity versions, the compiler will not insert these checks if the external call has a return value. Similar behavior can be achieved in earlier versions by using low-level calls, since low level calls never check for contract existence

*Instances (25)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

63:         return aToken.balanceOf(address(this));

71:         return aToken.balanceOf(address(this));

113:         _protocolWithdraw(aToken.balanceOf(address(this)), 0);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

83:         return IERC20(asset()).balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

70:         return rToken.balanceOf(address(this));

78:         return rToken.balanceOf(address(this));

123:         uint256 amountToWithdraw = rToken.balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

113:         uint256 shares = collateralToken.balanceOf(address(this));

123:         uint256 shares = collateralToken.balanceOf(address(this));

170:         uint256 shares = collateralToken.balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

182:         return IERC20(asset()).balanceOf(address(this)) + _totalAssets();

347:             uint256 claimedBalance = rewardAddress.balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

70:         return cToken.balanceOf(address(this));

76:         return cToken.balanceOf(address(this));

116:         _protocolWithdraw(cToken.balanceOf(address(this)), 0);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/Swapper.sol

162:         return IERC20(rewardToken_).balanceOf(_treasury) >= rewardAmount;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

448:         uint256 float = asset_.balanceOf(address(this));

460:                 uint256 withdrawable = strategy.strategy.previewRedeem(strategy.strategy.balanceOf(address(this)));

512:         totalAvailable = IERC20(asset()).balanceOf(address(this));

574:         total = IERC20(asset()).balanceOf(address(this));

578:             total += strategies[i].strategy.convertToAssets(strategies[i].strategy.balanceOf(address(this)));

897:         uint256 _totalAssets = IERC20(asset()).balanceOf(address(this));

937:         strategy.redeem(strategy.balanceOf(address(this)), address(this), address(this));

946:         uint256 _totalAssets = IERC20(asset()).balanceOf(address(this));

966:         uint256 balance = IERC20(asset()).balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-10"></a>[GAS-10] State variables only set in the constructor should be declared `immutable`

Variables only set in the constructor and never edited afterwards should be marked as immutable, as it would avoid the expensive storage-writing operation in the constructor (around **20 000 gas** per variable) and replace the expensive storage-reading operations (around **2100 gas** per reading) to a less expensive value reading (**3 gas**)

*Instances (19)*:

```solidity
File: src/managers/DeploymentManager.sol

33:         vaultFactory = IVaultFactory(vaultFactory_);

34:         implementationRegistry = IImplementationRegistry(implementationRegistry_);

35:         vaultRegistry = IVaultRegistry(vaultRegistry_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

33:         _treasury = treasury_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

36:         aToken = IAToken(_aToken);

41:         aaveIncentives = IAaveIncentives(aToken.getIncentivesController());

42:         lendingPool = ILendingPool(aToken.POOL());

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

41:         addressesProvider = ILendingPoolAddressesProvider(addressesProvider_);

42:         lendingPool = ILendingPool(addressesProvider.getLendingPool());

44:         rToken = IAToken(reserveData.aTokenAddress);

48:         incentiveController = IChefIncentivesController(rToken.getIncentivesController());

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

53:         siloRepository = ISiloRepository(siloRepository_);

54:         silo = ISilo(siloRepository.getSilo(siloAsset_));

70:         siloIncentivesController = ISiloIncentivesController(siloIncentivesController_);

72:         collateralToken = IERC20(temp.assetStorage.collateralToken);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

44:         cToken = ICToken(cToken_);

45:         rewarder = ICometRewarder(compoundRewarder_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

23:         _tokenRegistry = ITokenRegistry(tokenRegistry_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

67:         _treasury = treasury_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="GAS-11"></a>[GAS-11] Functions guaranteed to revert when called by normal users can be marked `payable`

If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (76)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

86:     function setVaultRegistry(address vaultRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {

246:     function repay(address tokenAddress, uint256 amount_, address userBlueprint) external onlyRole(BLUEPRINT_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/DeploymentManager.sol

42:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

49:     function removeImplementation(bytes32 id_) external onlyOwner {

58:     function deployNewVault(bytes32 id_, bytes calldata data_) external onlyOwner returns (address newVaultAddress) {

75:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

83:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {

89:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

79:     function setSwapperBaseRewardrate(uint16 baseRewardrate_) external onlyOwner {

88:     function setSwapperMaxProgressionFactor(uint16 maxProgressionFactor_) external onlyOwner {

97:     function setSwapperProgressionUpperBound(uint256 progressionUpperBound_) external onlyOwner {

105:     function setSwapperBonusRewardrateForUser(uint16 bonusRewardrateForUser_) external onlyOwner {

114:     function setSwapperBonusRewardrateForCtToken(uint16 bonusRewardrateForCtToken_) external onlyOwner {

123:     function setSwapperBonusRewardrateForSwapToken(uint16 bonusRewardrateForSwapToken_) external onlyOwner {

173:     function enableSwapperBonusRateForUser(address user_, bool enableBonusRate_) external onlyOwner {

182:     function enableSwapperBonusRateForRewardToken(address rewardToken_, bool enableBonusRate_) external onlyOwner {

191:     function enableSwapperBonusRateForCtToken(address ctAssetToken_, bool enableBonusRate_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/managers/VaultManager.sol

39:     function pauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

43:     function unpauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

47:     function pauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

61:     function unpauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

91:     function removeImplementation(bytes32 id_) external onlyRole(VAULT_MANAGER_ROLE) {

95:     function removeVault(address vault_, bytes32 vaultId_) external onlyRole(VAULT_MANAGER_ROLE) {

99:     function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {

103:     function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {

107:     function toggleIdleVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

120:     function removeStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

133:     function pushFundsToStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

137:     function pushFundsToSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

149:     function pullFundsFromSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

153:     function pullFundsFromStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

157:     function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {

161:     function batchClaimWithdrawal(address vault_, uint256 maxRequests) external onlyRole(VAULT_MANAGER_ROLE) {

165:     function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

109:     function unfinalizedAmount() external view virtual onlyOwner returns (uint256) {

131:     function requestWithdrawal(address recipient, uint256 amount) external virtual onlyOwner {

185:     function _finalize(uint256 _lastRequestIdToBeFinalized) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

35:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

50:     function removeImplementation(bytes32 id_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

111:     function updateIsReward(address tokenAddress_, bool isReward_) external override(ITokenRegistry) onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

46:     function addVault(address vault_, bytes32 vaultId_) external override onlyOwner {

68:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

116:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {

122:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

111:     function retireStrategy() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

89:     function setClaimRouter(address claimRouter_) external onlyOwner {

117:     function updateBorrowDebt(uint256 amount) external override onlyClaimRouter {

131:     function executeBorrowClaim(uint256 amount, address recipient) external override onlyClaimRouter {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

121:     function retireStrategy() external onlyOwner {

144:     function setEnableRewards(bool _rewardsEnabled) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

168:     function retireStrategy() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

191:     function addRewardToken(RewardToken calldata rewardToken_) external onlyOwner nonReentrant {

217:     function removeRewardToken(RewardToken calldata rewardToken_) external onlyOwner {

236:     function modifyRewardFeeForRewardToken(uint256 newFee_, RewardToken calldata rewardToken_) external onlyOwner {

261:     function setFeeRecipient(address feeRecipient_) external onlyOwner {

273:     function setDepositLimit(uint256 depositLimit_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

114:     function retireStrategy() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/Swapper.sol

105:     function setRewardManager(address rewardManager_) external onlyOwner {

113:     function disableTokenForSwap(address token_, bool disableSwap_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

194:     function pause() public onlyOwner {

202:     function unpause() public onlyOwner {

744:     function setVaultFees(VaultFees calldata newFees_) external takeFees onlyOwner {

754:     function setFeeRecipient(address newRecipient_) external onlyOwner {

769:     function setWithdrawalQueue(address withdrawalQueue_) external onlyOwner {

795:     function toggleVaultIdle() external onlyOwner {

837:     function removeStrategy(uint256 index_) external nonReentrant onlyOwner takeFees {

895:     function pushFundsToStrategies() public onlyOwner {

910:     function pullFundsFromStrategies() public onlyOwner {

930:     function pullFundsFromSingleStrategy(uint256 index_) public onlyOwner {

945:     function pushFundsIntoSingleStrategy(uint256 index_) external onlyOwner {

965:     function pushFundsIntoSingleStrategy(uint256 index_, uint256 amount) external onlyOwner {

978:     function setDepositLimit(uint256 newLimit_) external onlyOwner {

989:     function harvestRewards(bytes memory encodedData) external onlyOwner nonReentrant {

1059:     function batchClaimWithdrawal(uint256 maxRequests) external onlyOwner nonReentrant {

1098:     function requestFunds(uint256 amount) external onlyProtect {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-12"></a>[GAS-12] `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`)

Pre-increments and pre-decrements are cheaper.

For a `uint256 i` variable, the following is true with the Optimizer enabled at 10k:

**Increment:**

- `i += 1` is the most expensive form
- `i++` costs 6 gas less than `i += 1`
- `++i` costs 5 gas less than `i++` (11 gas less than `i += 1`)

**Decrement:**

- `i -= 1` is the most expensive form
- `i--` costs 11 gas less than `i -= 1`
- `--i` costs 5 gas less than `i--` (16 gas less than `i -= 1`)

Note that post-increments (or post-decrements) return the old value before incrementing or decrementing, hence the name *post-increment*:

```solidity
uint i = 1;  
uint j = 2;
require(j == i++, "This will be false as i is incremented after the comparison");
```
  
However, pre-increments (or pre-decrements) return the new value:
  
```solidity
uint i = 1;  
uint j = 2;
require(j == ++i, "This will be true as i is incremented before the comparison");
```

In the pre-increment case, the compiler has to create a temporary variable (when used) for returning `1` instead of `2`.

Consider using pre-increments and pre-decrements where they are relevant (meaning: not where post-increments/decrements logic are relevant).

*Saves 5 gas per instance*

*Instances (43)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

76:                 i++;

114:                 i++;

145:                     i++;

164:                     i++;

175:                 i++;

201:                         i++;

216:                     i++;

279:                     i++;

291:                         i++;

311:                     i++;

326:                 i++;

349:                 data.vaultsWithProtect++;

353:                 i++;

376:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/VaultManager.sol

56:                 i++;

70:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

79:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

67:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

159:                 count++;

161:                 count++;

164:                 i++;

172:                 count++;

175:                 count++;

178:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

104:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

108:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

65:                     temp.i++;

88:                 temp.i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

103:                     i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

263:                     i++;

326:                     i++;

474:                     i++;

520:                 i++;

545:                 i++;

561:                 i++;

580:                 i++;

878:                 i++;

916:                 i++;

1000:             for (uint256 k = 0; k < indices.length; k++) {

1017:                     j++;

1021:                 i++;

1049:                 i++;

1077:                 i++;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-13"></a>[GAS-13] Using `private` rather than `public` for constants, saves gas

If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (4)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

39:     bytes32 public constant BLUEPRINT_ROLE = keccak256("BLUEPRINT_ROLE");

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/VaultManager.sol

13:     bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/strategies/StrategyBase.sol

46:     uint8 public constant DECIMAL_OFFSET = 9;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

49:     uint8 public constant decimalOffset = 9;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-14"></a>[GAS-14] Superfluous event fields

`block.timestamp` and `block.number` are added to event information by default so adding them manually wastes gas

*Instances (1)*:

```solidity
File: src/queue/WithdrawalQueue.sol

60:     event WithdrawalsFinalized(uint256 indexed from, uint256 indexed to, uint256 timestamp);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

### <a name="GAS-15"></a>[GAS-15] Increments/decrements can be unchecked in for-loops

In Solidity 0.8+, there's a default overflow check on unsigned integers. It's possible to uncheck this in for-loops and save some gas at each iteration, but at the cost of some code readability, as this uncheck cannot be made inline.

[ethereum/solidity#10695](https://github.com/ethereum/solidity/issues/10695)

The change would be:

```diff
- for (uint256 i; i < numIterations; i++) {
+ for (uint256 i; i < numIterations;) {
 // ...  
+   unchecked { ++i; }
}  
```

These save around **25 gas saved** per instance.

The same can be applied with decrements (which should use `break` when `i == 0`).

The risk of overflow is non-existent for `uint256`.

*Instances (1)*:

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

1000:             for (uint256 k = 0; k < indices.length; k++) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-16"></a>[GAS-16] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (13)*:

```solidity
File: src/strategies/Aave/DataTypes.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/DataTypes.sol)

```solidity
File: src/strategies/Radiant/DataTypes.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/DataTypes.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

124:         if (amountToWithdraw > 0) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/IBaseSiloV1.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/IBaseSiloV1.sol)

```solidity
File: src/strategies/Silo/ISiloV1.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/ISiloV1.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

172:         if (amountToWithdraw > 0) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

111:         if (totalFee > 0 && _totalAssets > 0) {

246:         if (feeShares > 0) _mint(feeRecipient, feeShares);

309:         if (feeShares > 0) _mint(feeRecipient, feeShares);

424:         if (feeShares > 0) _mint(feeRecipient, feeShares);

691:         if (fees.protocolFee > 0) {

715:         if (fees.performanceFee.length > 0 && shareValue > highWaterMark) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="GAS-17"></a>[GAS-17] `internal` functions not called by the contract should be removed

If the functions are required by an interface, the contract should inherit from that interface and use the `override` keyword

*Instances (8)*:

```solidity
File: src/strategies/Silo/EasyMathV2.sol

10:     function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {

27:     function toShareRoundUp(

50:     function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {

67:     function toAmountRoundUp(

91:     function toValue(

104:     function sum(uint256[] memory _numbers) internal pure returns (uint256 s) {

122:     function calculateUtilization(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/swapper/OraclePlug.sol

87:     function _convertFromStableToCtAssetToken(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

## Non Critical Issues

| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Missing checks for `address(0)` when assigning values to address state variables | 2 |
| [NC-2](#NC-2) | Array indices should be referenced via `enum`s rather than via numeric literals | 8 |
| [NC-3](#NC-3) | `require()` should be used instead of `assert()` | 4 |
| [NC-4](#NC-4) | Constants should be in CONSTANT_CASE | 1 |
| [NC-5](#NC-5) | `constant`s should be defined rather than using magic numbers | 13 |
| [NC-6](#NC-6) | Control structures do not follow the Solidity Style Guide | 110 |
| [NC-7](#NC-7) | Critical Changes Should Use Two-step Procedure | 2 |
| [NC-8](#NC-8) | Default Visibility for constants | 2 |
| [NC-9](#NC-9) | Consider disabling `renounceOwnership()` | 8 |
| [NC-10](#NC-10) | Unused `error` definition | 1 |
| [NC-11](#NC-11) | Event is never emitted | 27 |
| [NC-12](#NC-12) | Events should use parameters to convey information | 4 |
| [NC-13](#NC-13) | Event missing indexed field | 24 |
| [NC-14](#NC-14) | Events that mark critical parameter changes should contain both the old and the new value | 18 |
| [NC-15](#NC-15) | Function ordering does not follow the Solidity style guide | 12 |
| [NC-16](#NC-16) | Functions should not be longer than 50 lines | 318 |
| [NC-17](#NC-17) | Interfaces should be defined in separate files from their usage | 19 |
| [NC-18](#NC-18) | Lack of checks in setters | 14 |
| [NC-19](#NC-19) | Missing Event for critical parameters change | 11 |
| [NC-20](#NC-20) | NatSpec is completely non-existent on functions that should have them | 26 |
| [NC-21](#NC-21) | Incomplete NatSpec: `@param` is missing on actually documented functions | 6 |
| [NC-22](#NC-22) | Incomplete NatSpec: `@return` is missing on actually documented functions | 2 |
| [NC-23](#NC-23) | Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor | 2 |
| [NC-24](#NC-24) | Consider using named mappings | 15 |
| [NC-25](#NC-25) | Owner can renounce while system is paused | 2 |
| [NC-26](#NC-26) | Adding a `return` statement when the function defines a named return variable, is redundant | 10 |
| [NC-27](#NC-27) | `require()` / `revert()` statements should have descriptive reason strings | 27 |
| [NC-28](#NC-28) | Take advantage of Custom Error's return value property | 86 |
| [NC-29](#NC-29) | Contract does not follow the Solidity style guide's suggested layout ordering | 10 |
| [NC-30](#NC-30) | TODO Left in the code | 1 |
| [NC-31](#NC-31) | Use Underscores for Number Literals (add an underscore every 3 digits) | 4 |
| [NC-32](#NC-32) | Internal and private variables and functions names should begin with an underscore | 16 |
| [NC-33](#NC-33) | Event is missing `indexed` fields | 39 |
| [NC-34](#NC-34) | `public` functions not called by the contract should be declared `external` instead | 10 |
| [NC-35](#NC-35) | Variables need not be initialized to zero | 22 |

### <a name="NC-1"></a>[NC-1] Missing checks for `address(0)` when assigning values to address state variables

*Instances (2)*:

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

33:         claimRouter = claimRouter_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

118:         _vault = vault_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

### <a name="NC-2"></a>[NC-2] Array indices should be referenced via `enum`s rather than via numeric literals

*Instances (8)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

120:         _assets[0] = address(aToken);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

88:         _rewardTokens[0] = incentiveController.rdntToken();

133:         _assets[0] = address(rToken);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

79:         temp.rewardTokenArray[0] = RewardToken(IERC20(getRewardTokenAddresses()[0]), rewardFee_, 0);

79:         temp.rewardTokenArray[0] = RewardToken(IERC20(getRewardTokenAddresses()[0]), rewardFee_, 0);

134:         _rewardTokens[0] = siloIncentivesController.REWARD_TOKEN();

180:         _assets[0] = address(collateralToken);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

84:         _rewardTokens[0] = rewardConfig.token;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

### <a name="NC-3"></a>[NC-3] `require()` should be used instead of `assert()`

Prior to solidity version 0.8.0, hitting an assert consumes the **remainder of the transaction's available gas** rather than returning it, as `require()`/`revert()` do. `assert()` should be avoided even past solidity version 0.8.0 as its [documentation](https://docs.soliditylang.org/en/v0.8.14/control-structures.html#panic-via-assert-and-error-via-require) states that "The assert function creates an error of type Panic(uint256). ... Properly functioning code should never create a Panic, not even on invalid external input. If this happens, then there is a bug in your contract which you should fix. Additionally, a require statement (or a custom error) are more friendly in terms of understanding what happened."

*Instances (4)*:

```solidity
File: src/queue/WithdrawalQueue.sol

145:         assert(_requestsByOwner[recipient].add(requestId));

171:             assert(_requestsByOwner[recipient].remove(_requestId));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/VaultRegistry.sol

60:         assert(vaultsByToken[underlyingAsset].add(vault_));

72:         assert(vaultsByToken[IERC4626(vault_).asset()].remove(vault_));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

### <a name="NC-4"></a>[NC-4] Constants should be in CONSTANT_CASE

For `constant` variable names, each word should use all capital letters, with underscores separating each word (CONSTANT_CASE)

*Instances (1)*:

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

49:     uint8 public constant decimalOffset = 9;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-5"></a>[NC-5] `constant`s should be defined rather than using magic numbers

Even [assembly](https://github.com/code-423n4/2022-05-opensea-seaport/blob/9d7ce4d08bf3c3010304a0476a785c70c0e90ae7/contracts/lib/TokenTransferrer.sol#L35-L39) can benefit from using readable constants instead of hex/numeric literals

*Instances (13)*:

```solidity
File: src/registries/VaultRegistry.sol

16:     uint256 public vaultByTokenLimit = 100;

18:     uint256 public totalVaultsAllowed = 1000;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

99:             value /= 10 ** _assetDecimals;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/StrategyBase.sol

349:                 uint256 collectedFee = claimedBalance.mulDiv(rewardTokens[i].fee, 10000, Math.Rounding.Ceil);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/OraclePlug.sol

49:             price.mulDiv(tokenAmount_, 10 ** quoteDecimals, Math.Rounding.Floor).mulDiv(

50:                 10 ** CONCRETE_USD_DECIMALS,

51:                 10 ** tokenDecimals,

79:             stableAmount_.mulDiv(10 ** tokenDecimals, 10 ** CONCRETE_USD_DECIMALS, Math.Rounding.Floor).mulDiv(

80:                 10 ** quoteDecimals,

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

669:         shares = assets.mulDiv(totalSupply() + 10 ** decimalOffset, totalAssets() + 1, rounding);

680:         return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** decimalOffset, rounding);

698:                 ) / 10000; // Normalize the fee percentage

881:         if (allotmentTotals != 10000) revert AllotmentTotalTooHigh();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-6"></a>[NC-6] Control structures do not follow the Solidity Style Guide

See the [control structures](https://docs.soliditylang.org/en/latest/style-guide.html#control-structures) section of the Solidity Style Guide

*Instances (110)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

67:         if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();

68:         if (owner == address(0)) revert InvalidDefaultAdminAddress();

74:             if (blueprint_[i] != address(0)) _grantRole(BLUEPRINT_ROLE, blueprint_[i]);

87:         if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();

153:             if (

259:         if (amount_ == 0) revert ZeroAmount();

264:         if (debtVaults.vaultsWithProtect == 0) revert NoProtectionStrategiesFound();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/RewardManager.sol

60:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

61:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

62:         if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

63:         if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

64:         if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

80:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

89:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

106:         if (bonusRewardrateForUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

115:         if (bonusRewardrateForCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

124:         if (bonusRewardrateForSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

145:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

146:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

147:         if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

148:         if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

149:         if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

174:         if (user_ == address(0)) revert Errors.InvalidUserAddress();

285:         if (!(owner() == _msgSender() || user_ == _msgSender())) revert Errors.InvalidUserAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

115:         if (_requestId == 0 || _requestId > lastRequestId) revert InvalidRequestId(_requestId);

157:         if (_requestId == 0) revert InvalidRequestId(_requestId);

158:         if (_requestId < lastFinalizedRequestId) revert RequestNotFoundOrNotFinalized(_requestId);

162:         if (request.claimed) revert RequestAlreadyClaimed(_requestId);

187:             if (_lastRequestIdToBeFinalized > lastRequestId) revert InvalidRequestId(_lastRequestIdToBeFinalized);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/TokenRegistry.sol

32:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

52:         if (isRegistered(tokenAddress_)) revert Errors.TokenAlreadyRegistered(tokenAddress_);

62:         if (!_listedTokens.add(tokenAddress_)) revert Errors.AdditionFail();

75:         if (!_listedTokens.remove(tokenAddress_)) revert Errors.RemoveFail();

113:             revert Errors.UnregisteredTokensCannotBeRewards(tokenAddress_); // check if token is registered

195:         if (!isRegistered(tokenAddress_)) revert Errors.TokenNotRegistered(tokenAddress_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

47:         if (vault_ == address(0)) revert VaultZeroAddress();

56:         if (allVaultsCreated.length > totalVaultsAllowed) revert TotalVaultsAllowedExceeded(allVaultsCreated.length);

123:         if (totalVaultsAllowed_ < allVaultsCreated.length) revert TotalVaultsAllowedExceeded(allVaultsCreated.length);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

117:         if (address(aaveIncentives) == address(0)) return;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

69:         if (totalSupply_ == 0) return 1;

90:         if (claimRouter_ == address(0)) revert InvalidClaimRouterAddress();

118:         if (borrowDebt < amount) revert InvalidSubstraction();

132:         if (amount == 0) revert ZeroAmount();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

37:         if (addressesProvider_ == address(0)) revert ZeroAddress();

45:         if (rToken.UNDERLYING_ASSET_ADDRESS() != address(baseAsset_)) revert AssetDivergence();

86:         if (!rewardsEnabled) return new address[](0);

130:         if (!rewardsEnabled) return;

131:         if (address(incentiveController) == address(0)) return;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

127:         if (_totalDeposits == 0 || _totalBorrowAmount == 0) return 0;

136:         if (utilization > _dp) utilization = _dp;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

50:         if (siloRepository_ == address(0)) revert ZeroAddress();

51:         if (siloIncentivesController_ == address(0)) revert ZeroAddress();

55:         if (address(silo) == address(0)) revert ZeroAddress();

68:             if (temp.i == temp.length) revert AssetDivergence();

92:         if (address(collateralToken) == address(0)) revert InvalidAssetAddress();

178:         if (address(siloIncentivesController) == address(0)) return;

183:         if (rewardAmount == 0) return;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

54:         if (msg.sender != _vault) revert OnlyVault(msg.sender);

98:                 if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();

109:         if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();

113:         if (depositLimit_ == 0) revert InvalidDepositLimit();

135:         if (shares_ == 0 || assets_ == 0) revert ZeroAmount();

163:         if (shares_ == 0 || assets_ == 0) revert ZeroAmount();

262:         if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();

274:         if (depositLimit_ == 0) revert InvalidDepositLimit();

309:                 index = i; // Set the index if the token is found.

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

59:         if (asset() != baseToken) revert AssetDivergence(baseToken);

90:         if (cToken.isSupplyPaused()) revert SupplyPaused();

97:         if (cToken.isWithdrawPaused()) revert WithdrawPaused();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

22:         if (tokenRegistry_ == address(0)) revert Errors.InvalidTokenRegistry();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

66:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

83:         if (!_tokenRegistry.isRewardToken(rewardToken_)) revert Errors.NotValidRewardToken(rewardToken_);

133:         if (!_tokenRegistry.isRegistered(rewardToken_)) return (0, false, false);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

109:         if (shareValue > highWaterMark) highWaterMark = shareValue;

156:         if (address(baseAsset_) == address(0)) revert InvalidAssetAddress();

233:         if (assets_ > maxDeposit(receiver_) || assets_ > depositLimit) revert MaxError();

243:         if (shares <= DUST) revert ZeroAmount();

246:         if (feeShares > 0) _mint(feeRecipient, feeShares);

296:         if (shares_ == 0) revert ZeroAmount();

306:         if (assets > maxMint(receiver_)) revert MaxError();

309:         if (feeShares > 0) _mint(feeRecipient, feeShares);

356:         if (receiver_ == address(0)) revert InvalidRecipient();

357:         if (shares_ == 0) revert ZeroAmount();

358:         if (shares_ > maxRedeem(owner_)) revert MaxError();

393:         if (receiver_ == address(0)) revert InvalidRecipient();

394:         if (assets_ > maxWithdraw(owner_)) revert MaxError();

396:         if (shares <= DUST) revert ZeroAmount();

424:         if (feeShares > 0) _mint(feeRecipient, feeShares);

453:             uint256 diff = amount_ - float;

462:                     revert InsufficientFunds(strategy.strategy, diff * strategy.allocation.amount, withdrawable);

590:         if (total < unfinalized) revert InvalidSubstraction();

756:         if (newRecipient_ == address(0)) revert InvalidFeeRecipient();

771:         if (withdrawalQueue_ == address(0)) revert InvalidWithdrawlQueue();

773:             if (withdrawalQueue.unfinalizedAmount() != 0) revert UnfinalizedWithdrawl(address(withdrawalQueue));

825:         if (address(removedStrategy) != address(0)) emit StrategyRemoved(address(removedStrategy));

839:         if (index_ >= len) revert InvalidIndex(index_);

853:         if (from != address(0)) updateUserRewardsToCurrent(from);

854:         if (to != address(0)) updateUserRewardsToCurrent(to);

871:         if (len != strategies.length) revert InvalidLength(len, strategies.length);

881:         if (allotmentTotals != 10000) revert AllotmentTotalTooHigh();

896:         if (vaultIdle) revert VaultIsIdle();

948:         if (index_ >= strategies.length) revert InvalidIndex(index_);

950:         if (vaultIdle) revert VaultIsIdle();

967:         if (amount > balance) revert InsufficientVaultFunds(address(this), amount, balance);

968:         if (vaultIdle) revert VaultIsIdle();

1013:                     if (rewardIndex[rewardToken] == 0) rewardAddresses.push(rewardToken);

1060:         if (address(withdrawalQueue) == address(0)) revert QueueNotSet();

1072:             if (newAvailiableAssets == availableAssets) break;

1113:         if (receiver_ == address(0)) revert InvalidRecipient();

1114:         if (totalSupply() == 0) feesUpdatedAt = block.timestamp;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-7"></a>[NC-7] Critical Changes Should Use Two-step Procedure

The critical procedures should be two step process.

See similar findings in previous Code4rena contests for reference: <https://code4rena.com/reports/2022-06-illuminate/#2-critical-changes-should-use-two-step-procedure>

**Recommended Mitigation Steps**

Lack of two-step procedure for critical operations leaves them error-prone. Consider adding two step procedure on the critical functions.

*Instances (2)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

86:     function setVaultRegistry(address vaultRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

### <a name="NC-8"></a>[NC-8] Default Visibility for constants

Some constants are using the default visibility. For readability, consider explicitly declaring them as `internal`.

*Instances (2)*:

```solidity
File: src/interfaces/Constants.sol

4: uint8 constant CONCRETE_USD_DECIMALS = 6;

5: uint256 constant BASISPOINTS = 10_000;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/Constants.sol)

### <a name="NC-9"></a>[NC-9] Consider disabling `renounceOwnership()`

If the plan for your project does not include eventually giving up all ownership control, consider overwriting OpenZeppelin's `Ownable`'s `renounceOwnership()` function in order to disable it.

*Instances (8)*:

```solidity
File: src/factories/VaultFactory.sol

14: contract VaultFactory is Ownable, Errors, IVaultFactory {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/managers/DeploymentManager.sol

16: contract DeploymentManager is Ownable, Errors, IVaultDeploymentManager {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

34: contract RewardManager is RewardManagerEvents, Ownable {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

15: contract WithdrawalQueue is Ownable, IWithdrawalQueue {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

12: contract ImplementationRegistry is Ownable, Errors, IImplementationRegistry {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

23: contract TokenRegistry is ITokenRegistry, TokenRegistryEvents, Ownable {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

13: contract VaultRegistry is IVaultRegistry, Ownable, Errors {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/swapper/Swapper.sol

45: contract Swapper is OraclePlug, Ownable, SwapperEvents, ReentrancyGuard, ISwapper {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="NC-10"></a>[NC-10] Unused `error` definition

Note that there may be cases where an error superficially appears to be used, but this is only because there are multiple definitions of the error in different files. In such cases, the error definition should be moved into a separate file. The instances below are the unused definitions.

*Instances (1)*:

```solidity
File: src/queue/WithdrawalQueue.sol

63:     error InvalidRequestIdRange(uint256 startId, uint256 endId);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

### <a name="NC-11"></a>[NC-11] Event is never emitted

The following are defined but never emitted. They can be removed to make the code cleaner.

*Instances (27)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

21:     event TokenCascadeUpdated();

22:     event BlueprintRoleGranted(address blueprint);

23:     event VaultRegistryUpdated(address vaultRegistry);

24:     event ClaimRequested(address indexed protectionStrat, uint256 amount, address asset, address userBlueprint);

25:     event Repayment(address indexed protectionStrat, uint256 amount);

26:     event RewardAdded(address indexed protectionStrat, uint256 amount);

27:     event DustCleaned(address indexed protectionStrat, uint256 amount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/RewardManager.sol

16:     event SwapperRewardsUpdated(

24:     event SwapperBaseRewardrateUpdated(uint16 baseRewardrate);

25:     event SwapperMaxProgressionFactorUpdated(uint16 maxProgressionFactor);

26:     event SwapperProgressionUpperBoundUpdated(uint256 progressionUpperBound);

27:     event SwapperBonusRewardrateForUserUpdated(uint16 bonusRewardrateUser);

28:     event SwapperBonusRewardrateForCtTokenUpdated(uint16 bonusRewardrateCtToken);

29:     event SwapperBonusRewardrateForSwapTokenUpdated(uint16 bonusRewardrateSwapToken);

30:     event SwapperBonusRateForRewardTokenEnabled(address rewardToken, bool enableBonusRate);

31:     event SwapperBonusRateForCtTokenEnabled(address ctAssetToken, bool enableBonusRate);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

16:     event TokenRegistered(address indexed token, bool isReward, OracleInformation oracle);

17:     event TokenUnregistered(address indexed token);

18:     event TokenRemoved(address indexed token);

19:     event IsRewardUpdated(address indexed token, bool isReward);

20:     event OracleUpdated(address indexed token, address oracle, uint8 decimals, string pair);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

12:     event BorrowDebtRepayed(uint256 prevAmount, uint256 substractedAmount);

13:     event BorrowClaimExecuted(uint256 amount, address recipient);

14:     event ClaimRouterAddressUpdated(address claimRouter);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/swapper/Swapper.sol

28:     event Swapped(

36:     event TreasuryUpdated(address treasury);

38:     event RewardManagerUpdated(address rewardManager);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="NC-12"></a>[NC-12] Events should use parameters to convey information

For example, rather than using `event Paused()` and `event Unpaused()`, use `event PauseState(address indexed whoChangedIt, bool wasPaused, bool isNowPaused)`

*Instances (4)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

21:     event TokenCascadeUpdated();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/VaultManager.sol

18:     event AllVaultsPaused();

19:     event AllVaultsUnpaused();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

92:     event RewardsHarvested();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-13"></a>[NC-13] Event missing indexed field

Index event fields make the field more quickly accessible [to off-chain tools](https://ethereum.stackexchange.com/questions/40396/can-somebody-please-explain-the-concept-of-event-indexing) that parse events. This is especially useful when it comes to filtering based on an address. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Where applicable, each `event` should use three `indexed` fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three applicable fields, all of the applicable fields should be indexed.

*Instances (24)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

22:     event BlueprintRoleGranted(address blueprint);

23:     event VaultRegistryUpdated(address vaultRegistry);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/interfaces/IBeraOracle.sol

29:     event CurrencyPairsAdded(string[] currencyPairs);

32:     event CurrencyPairsRemoved(string[] currencyPairs);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IBeraOracle.sol)

```solidity
File: src/interfaces/IConcreteMultiStrategyVault.sol

42:     event ToggleVaultIdle(bool pastValue, bool newValue);

43:     event StrategyAdded(address newStrategy);

44:     event StrategyRemoved(address oldStrategy);

45:     event DepositLimitSet(uint256 limit);

46:     event StrategyAllocationsChanged(Allocation[] newAllocations);

47:     event WithdrawalQueueUpdated(address oldQueue, address newQueue);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IConcreteMultiStrategyVault.sol)

```solidity
File: src/managers/RewardManager.sol

16:     event SwapperRewardsUpdated(

24:     event SwapperBaseRewardrateUpdated(uint16 baseRewardrate);

25:     event SwapperMaxProgressionFactorUpdated(uint16 maxProgressionFactor);

26:     event SwapperProgressionUpperBoundUpdated(uint256 progressionUpperBound);

27:     event SwapperBonusRewardrateForUserUpdated(uint16 bonusRewardrateUser);

28:     event SwapperBonusRewardrateForCtTokenUpdated(uint16 bonusRewardrateCtToken);

29:     event SwapperBonusRewardrateForSwapTokenUpdated(uint16 bonusRewardrateSwapToken);

30:     event SwapperBonusRateForRewardTokenEnabled(address rewardToken, bool enableBonusRate);

31:     event SwapperBonusRateForCtTokenEnabled(address ctAssetToken, bool enableBonusRate);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

12:     event BorrowDebtRepayed(uint256 prevAmount, uint256 substractedAmount);

13:     event BorrowClaimExecuted(uint256 amount, address recipient);

14:     event ClaimRouterAddressUpdated(address claimRouter);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/swapper/Swapper.sol

36:     event TreasuryUpdated(address treasury);

38:     event RewardManagerUpdated(address rewardManager);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="NC-14"></a>[NC-14] Events that mark critical parameter changes should contain both the old and the new value

This should especially be done if the new value is not required to be different from the old value

*Instances (18)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

86:     function setVaultRegistry(address vaultRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
            if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();
            vaultRegistry = IVaultRegistry(vaultRegistry_);
            emit VaultRegistryUpdated(vaultRegistry_);

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {
            delete tokenCascade;
            _setTokenCascade(tokenCascade_);
            emit TokenCascadeUpdated();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/RewardManager.sol

79:     function setSwapperBaseRewardrate(uint16 baseRewardrate_) external onlyOwner {
            if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();
            _swapperRewards.baseRewardrate = baseRewardrate_;
            emit SwapperBaseRewardrateUpdated(baseRewardrate_);

88:     function setSwapperMaxProgressionFactor(uint16 maxProgressionFactor_) external onlyOwner {
            if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();
            _swapperRewards.maxProgressionFactor = maxProgressionFactor_;
            emit SwapperMaxProgressionFactorUpdated(maxProgressionFactor_);

97:     function setSwapperProgressionUpperBound(uint256 progressionUpperBound_) external onlyOwner {
            _swapperRewards.progressionUpperBound = SafeCast.toUint176(progressionUpperBound_);
            emit SwapperProgressionUpperBoundUpdated(progressionUpperBound_);

105:     function setSwapperBonusRewardrateForUser(uint16 bonusRewardrateForUser_) external onlyOwner {
             if (bonusRewardrateForUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();
             _swapperRewards.bonusRewardrateUser = bonusRewardrateForUser_;
             emit SwapperBonusRewardrateForUserUpdated(bonusRewardrateForUser_);

114:     function setSwapperBonusRewardrateForCtToken(uint16 bonusRewardrateForCtToken_) external onlyOwner {
             if (bonusRewardrateForCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();
             _swapperRewards.bonusRewardrateCtToken = bonusRewardrateForCtToken_;
             emit SwapperBonusRewardrateForCtTokenUpdated(bonusRewardrateForCtToken_);

123:     function setSwapperBonusRewardrateForSwapToken(uint16 bonusRewardrateForSwapToken_) external onlyOwner {
             if (bonusRewardrateForSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();
             _swapperRewards.bonusRewardrateSwapToken = bonusRewardrateForSwapToken_;
             emit SwapperBonusRewardrateForSwapTokenUpdated(bonusRewardrateForSwapToken_);

137:     function setSwapperRewards(
             uint16 baseRewardrate_,
             uint16 maxProgressionFactor_,
             uint256 progressionUpperBound_,
             uint16 bonusRewardrateUser_,
             uint16 bonusRewardrateCtToken_,
             uint16 bonusRewardrateSwapToken_
         ) external onlyOwner {
             if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();
             if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();
             if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();
             if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();
             if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();
     
             _swapperRewards = SwapperRewards({
                 baseRewardrate: baseRewardrate_,
                 maxProgressionFactor: maxProgressionFactor_,
                 progressionUpperBound: SafeCast.toUint176(progressionUpperBound_),
                 bonusRewardrateUser: bonusRewardrateUser_,
                 bonusRewardrateCtToken: bonusRewardrateCtToken_,
                 bonusRewardrateSwapToken: bonusRewardrateSwapToken_
             });
             emit SwapperRewardsUpdated(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

93:     function updateOracle(
            address tokenAddress_,
            address oracleAddr_,
            uint8 oracleDecimals_,
            string memory oraclePair_
        ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {
            _token[tokenAddress_].oracle = OracleInformation({
                addr: oracleAddr_,
                decimals: oracleDecimals_,
                pair: oraclePair_
            });
    
            emit OracleUpdated(tokenAddress_, oracleAddr_, oracleDecimals_, oraclePair_);

111:     function updateIsReward(address tokenAddress_, bool isReward_) external override(ITokenRegistry) onlyOwner {
             if (!isRegistered(tokenAddress_) && isReward_) {
                 revert Errors.UnregisteredTokensCannotBeRewards(tokenAddress_); // check if token is registered
             }
             _token[tokenAddress_].isReward = isReward_;
             emit IsRewardUpdated(tokenAddress_, isReward_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

89:     function setClaimRouter(address claimRouter_) external onlyOwner {
            if (claimRouter_ == address(0)) revert InvalidClaimRouterAddress();
            claimRouter = claimRouter_;
            emit ClaimRouterAddressUpdated(claimRouter_);

117:     function updateBorrowDebt(uint256 amount) external override onlyClaimRouter {
             if (borrowDebt < amount) revert InvalidSubstraction();
             emit BorrowDebtRepayed(borrowDebt, amount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

144:     function setEnableRewards(bool _rewardsEnabled) external onlyOwner {
             rewardsEnabled = _rewardsEnabled;
             emit SetEnableRewards(msg.sender, _rewardsEnabled);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/swapper/Swapper.sol

105:     function setRewardManager(address rewardManager_) external onlyOwner {
             _rewardManager = IRewardManager(rewardManager_);
             emit RewardManagerUpdated(rewardManager_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

754:     function setFeeRecipient(address newRecipient_) external onlyOwner {
             // Validate the new recipient address
             if (newRecipient_ == address(0)) revert InvalidFeeRecipient();
     
             // Emit an event for the fee recipient update
             emit FeeRecipientUpdated(feeRecipient, newRecipient_);

769:     function setWithdrawalQueue(address withdrawalQueue_) external onlyOwner {
             // Validate the new recipient address
             if (withdrawalQueue_ == address(0)) revert InvalidWithdrawlQueue();
             if (address(withdrawalQueue) != address(0)) {
                 if (withdrawalQueue.unfinalizedAmount() != 0) revert UnfinalizedWithdrawl(address(withdrawalQueue));
             }
             // Emit an event for the fee recipient update
             emit WithdrawalQueueUpdated(address(withdrawalQueue), withdrawalQueue_);

978:     function setDepositLimit(uint256 newLimit_) external onlyOwner {
             depositLimit = newLimit_;
             emit DepositLimitSet(newLimit_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-15"></a>[NC-15] Function ordering does not follow the Solidity style guide

According to the [Solidity style guide](https://docs.soliditylang.org/en/v0.8.17/style-guide.html#order-of-functions), functions should be laid out in the following order :`constructor()`, `receive()`, `fallback()`, `external`, `public`, `internal`, `private`, but the cases below do not follow this pattern

*Instances (12)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

1: 
   Current order:
   external setVaultRegistry
   external setTokenCascade
   internal _setTokenCascade
   internal _getStrategy
   external requestToken
   external addRewards
   external repay
   private _addTokensToStrategy
   private _getTokenTotalBorrowDebt
   external getTokenTotalAvaliableForProtection
   
   Suggested order:
   external setVaultRegistry
   external setTokenCascade
   external requestToken
   external addRewards
   external repay
   external getTokenTotalAvaliableForProtection
   internal _setTokenCascade
   internal _getStrategy
   private _addTokensToStrategy
   private _getTokenTotalBorrowDebt

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

1: 
   Current order:
   external getWithdrawalStatus
   external getWithdrawalRequests
   public getLastRequestId
   public getLastFinalizedRequestId
   public unfinalizedRequestNumber
   external unfinalizedAmount
   internal _getStatus
   external requestWithdrawal
   external prepareWithdrawal
   external _finalize
   
   Suggested order:
   external getWithdrawalStatus
   external getWithdrawalRequests
   external unfinalizedAmount
   external requestWithdrawal
   external prepareWithdrawal
   external _finalize
   public getLastRequestId
   public getLastFinalizedRequestId
   public unfinalizedRequestNumber
   internal _getStatus

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/TokenRegistry.sol

1: 
   Current order:
   external registerToken
   external removeToken
   external unregisterToken
   external updateOracle
   external updateIsReward
   external getOracle
   public isRegistered
   public isRewardToken
   public getTokens
   external getSubsetOfTokens
   public getTreasury
   
   Suggested order:
   external registerToken
   external removeToken
   external unregisterToken
   external updateOracle
   external updateIsReward
   external getOracle
   external getSubsetOfTokens
   public isRegistered
   public isRewardToken
   public getTokens
   public getTreasury

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

1: 
   Current order:
   external addVault
   external removeVault
   external getAllVaults
   external getVaultsByImplementationId
   external getVaultsByToken
   internal _handleRemoveVault
   external setVaultByTokenLimit
   external setTotalVaultsAllowed
   
   Suggested order:
   external addVault
   external removeVault
   external getAllVaults
   external getVaultsByImplementationId
   external getVaultsByToken
   external setVaultByTokenLimit
   external setTotalVaultsAllowed
   internal _handleRemoveVault

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

1: 
   Current order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   internal _totalAssets
   public getRewardTokenAddresses
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _handleRewardsOnWithdraw
   external retireStrategy
   internal _getRewardsToStrategy
   
   Suggested order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   external retireStrategy
   public getRewardTokenAddresses
   internal _totalAssets
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _handleRewardsOnWithdraw
   internal _getRewardsToStrategy

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

1: 
   Current order:
   external isProtectStrategy
   external highWatermark
   public getAvailableAssetsForWithdrawal
   external setClaimRouter
   internal _totalAssets
   external getBorrowDebt
   external updateBorrowDebt
   external executeBorrowClaim
   private _requestFromVault
   internal _handleRewardsOnWithdraw
   internal _getRewardsToStrategy
   public getRewardTokenAddresses
   
   Suggested order:
   external isProtectStrategy
   external highWatermark
   external setClaimRouter
   external getBorrowDebt
   external updateBorrowDebt
   external executeBorrowClaim
   public getAvailableAssetsForWithdrawal
   public getRewardTokenAddresses
   internal _totalAssets
   internal _handleRewardsOnWithdraw
   internal _getRewardsToStrategy
   private _requestFromVault

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

1: 
   Current order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   internal _totalAssets
   public getRewardTokenAddresses
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _handleRewardsOnWithdraw
   external retireStrategy
   internal _getRewardsToStrategy
   external setEnableRewards
   
   Suggested order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   external retireStrategy
   external setEnableRewards
   public getRewardTokenAddresses
   internal _totalAssets
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _handleRewardsOnWithdraw
   internal _getRewardsToStrategy

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

1: 
   Current order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   internal _totalAssets
   public getRewardTokenAddresses
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _handleRewardsOnWithdraw
   external retireStrategy
   internal _getRewardsToStrategy
   public balanceOfUnderlying
   
   Suggested order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   external retireStrategy
   public getRewardTokenAddresses
   public balanceOfUnderlying
   internal _totalAssets
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _handleRewardsOnWithdraw
   internal _getRewardsToStrategy

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

1: 
   Current order:
   internal __StrategyBase_init
   internal _deposit
   internal _withdraw
   public totalAssets
   external addRewardToken
   external removeRewardToken
   external modifyRewardFeeForRewardToken
   internal _handleRewardsOnWithdraw
   external setFeeRecipient
   external setDepositLimit
   external getRewardTokens
   internal _getIndex
   internal _getRewardTokens
   public harvestRewards
   public getRewardTokenAddresses
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _totalAssets
   internal _getRewardsToStrategy
   
   Suggested order:
   external addRewardToken
   external removeRewardToken
   external modifyRewardFeeForRewardToken
   external setFeeRecipient
   external setDepositLimit
   external getRewardTokens
   public totalAssets
   public harvestRewards
   public getRewardTokenAddresses
   internal __StrategyBase_init
   internal _deposit
   internal _withdraw
   internal _handleRewardsOnWithdraw
   internal _getIndex
   internal _getRewardTokens
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _totalAssets
   internal _getRewardsToStrategy

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

1: 
   Current order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   internal _totalAssets
   public getRewardTokenAddresses
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _getRewardsToStrategy
   internal _handleRewardsOnWithdraw
   external retireStrategy
   
   Suggested order:
   external isProtectStrategy
   external getAvailableAssetsForWithdrawal
   external retireStrategy
   public getRewardTokenAddresses
   internal _totalAssets
   internal _protocolDeposit
   internal _protocolWithdraw
   internal _getRewardsToStrategy
   internal _handleRewardsOnWithdraw

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

1: 
   Current order:
   internal _getPriceFromOracle
   internal _convertFromTokenToStable
   internal _convertFromCtAssetTokenToStable
   internal _convertFromStableToToken
   internal _convertFromStableToCtAssetToken
   public getTokenRegistry
   
   Suggested order:
   public getTokenRegistry
   internal _getPriceFromOracle
   internal _convertFromTokenToStable
   internal _convertFromCtAssetTokenToStable
   internal _convertFromStableToToken
   internal _convertFromStableToCtAssetToken

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

1: 
   Current order:
   external initialize
   public decimals
   public pause
   public unpause
   external deposit
   public deposit
   external mint
   public mint
   external redeem
   public redeem
   external withdraw
   public withdraw
   private _withdraw
   private _withdrawStrategyFunds
   private claimWithdrawal
   public getRewardTokens
   public getAvailableAssetsForWithdrawal
   external getUserRewards
   external getTotalRewardsClaimed
   public totalAssets
   public previewDeposit
   public previewMint
   public previewWithdraw
   public previewRedeem
   public maxMint
   internal _convertToShares
   internal _convertToAssets
   public accruedProtocolFee
   public accruedPerformanceFee
   public getVaultFees
   external takePortfolioAndProtocolFees
   external setVaultFees
   external setFeeRecipient
   external setWithdrawalQueue
   external getStrategies
   external toggleVaultIdle
   external addStrategy
   external removeStrategy
   internal _update
   external changeAllocations
   public pushFundsToStrategies
   public pullFundsFromStrategies
   public pullFundsFromSingleStrategy
   external pushFundsIntoSingleStrategy
   external pushFundsIntoSingleStrategy
   external setDepositLimit
   external harvestRewards
   private updateUserRewardsToCurrent
   external batchClaimWithdrawal
   external claimRewards
   external requestFunds
   private _validateAndUpdateDepositTimestamps
   
   Suggested order:
   external initialize
   external deposit
   external mint
   external redeem
   external withdraw
   external getUserRewards
   external getTotalRewardsClaimed
   external takePortfolioAndProtocolFees
   external setVaultFees
   external setFeeRecipient
   external setWithdrawalQueue
   external getStrategies
   external toggleVaultIdle
   external addStrategy
   external removeStrategy
   external changeAllocations
   external pushFundsIntoSingleStrategy
   external pushFundsIntoSingleStrategy
   external setDepositLimit
   external harvestRewards
   external batchClaimWithdrawal
   external claimRewards
   external requestFunds
   public decimals
   public pause
   public unpause
   public deposit
   public mint
   public redeem
   public withdraw
   public getRewardTokens
   public getAvailableAssetsForWithdrawal
   public totalAssets
   public previewDeposit
   public previewMint
   public previewWithdraw
   public previewRedeem
   public maxMint
   public accruedProtocolFee
   public accruedPerformanceFee
   public getVaultFees
   public pushFundsToStrategies
   public pullFundsFromStrategies
   public pullFundsFromSingleStrategy
   internal _convertToShares
   internal _convertToAssets
   internal _update
   private _withdraw
   private _withdrawStrategyFunds
   private claimWithdrawal
   private updateUserRewardsToCurrent
   private _validateAndUpdateDepositTimestamps

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-16"></a>[NC-16] Functions should not be longer than 50 lines

Overly complex code can make understanding functionality more difficult, try to further modularize your code to ensure readability

*Instances (318)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

86:     function setVaultRegistry(address vaultRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {

104:     function _setTokenCascade(address[] memory tokenCascade_) internal {

126:     function _getStrategy(address tokenAddress, uint256 amount) internal view returns (address, bool) {

246:     function repay(address tokenAddress, uint256 amount_, address userBlueprint) external onlyRole(BLUEPRINT_ROLE) {

258:     function _addTokensToStrategy(address tokenAddress, uint256 amount_, address userBlueprint, bool isReward) private {

340:     function _getTokenTotalBorrowDebt(address tokenAddress) private view returns (DebtVaults memory data) {

365:     function getTokenTotalAvaliableForProtection(address tokenAddress) external view returns (uint256 total) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/interfaces/IBeraOracle.sol

11:     function addCurrencyPairs(string[] calldata pairs) external returns (bool);

14:     function getAllCurrencyPairs() external view returns (string[] memory);

17:     function getDecimals(string calldata pair) external view returns (uint8);

20:     function getPrice(string calldata pair) external view returns (int256, uint256, uint64);

23:     function hasCurrencyPair(string calldata pair) external view returns (bool);

26:     function removeCurrencyPairs(string[] calldata pairs) external returns (bool);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IBeraOracle.sol)

```solidity
File: src/interfaces/IClaimRouter.sol

19:     function addRewards(address tokenAddress, uint256 amount, address userBlueprint) external;

20:     function repay(address tokenAddress, uint256 amount, address userBlueprint) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IClaimRouter.sol)

```solidity
File: src/interfaces/IConcreteMultiStrategyVault.sol

51:     function setVaultFees(VaultFees calldata newFees_) external;

52:     function setFeeRecipient(address newRecipient_) external;

54:     function addStrategy(uint256 index_, bool replace_, Strategy calldata newStrategy_) external;

56:     function changeAllocations(Allocation[] calldata allocations_, bool redistribute_) external;

57:     function setDepositLimit(uint256 limit_) external;

59:     function pushFundsIntoSingleStrategy(uint256 index_, uint256 amount) external;

60:     function pushFundsIntoSingleStrategy(uint256 index_) external;

62:     function pullFundsFromSingleStrategy(uint256 index_) external;

63:     function protectStrategy() external view returns (address);

64:     function getAvailableAssetsForWithdrawal() external view returns (uint256);

66:     function setWithdrawalQueue(address withdrawalQueue_) external;

67:     function batchClaimWithdrawal(uint256 maxRequests) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IConcreteMultiStrategyVault.sol)

```solidity
File: src/interfaces/IImplementationRegistry.sol

10:     function addImplementation(bytes32 id_, ImplementationData calldata implementation_) external;

11:     function getImplementation(bytes32 id_) external view returns (ImplementationData memory);

12:     function removeImplementation(bytes32 id_) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IImplementationRegistry.sol)

```solidity
File: src/interfaces/IMockProtectStrategy.sol

7:     function getAvailableAssetsForWithdrawal() external view returns (uint256);

9:     function setAvailableAssetsZero(bool _avaliableAssetsZero) external;

11:     function executeBorrowClaim(uint256 amount, address recipient) external;

13:     function getBorrowDebt() external view returns (uint256);

15:     function updateBorrowDebt(uint256 amount) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IMockProtectStrategy.sol)

```solidity
File: src/interfaces/IMockStrategy.sol

7:     function getAvailableAssetsForWithdrawal() external view returns (uint256);

9:     function setAvailableAssetsZero(bool _avaliableAssetsZero) external;

11:     function isProtectStrategy() external returns (bool);

13:     function setHighWatermark(uint256 _highWatermark) external;

15:     function highWatermark() external view returns (uint256);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IMockStrategy.sol)

```solidity
File: src/interfaces/IProtectStrategy.sol

7:     function executeBorrowClaim(uint256 amount, address recipient) external;

9:     function getBorrowDebt() external view returns (uint256);

11:     function updateBorrowDebt(uint256 amount) external;

12:     function highWatermark() external view returns (uint256);

13:     function setClaimRouter(address claimRouter_) external;

14:     function claimRouter() external view returns (address);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IProtectStrategy.sol)

```solidity
File: src/interfaces/IRewardManager.sol

22:     function getSwapperBaseRewardrate() external view returns (uint16);

26:     function getMaxProgressionFactor() external view returns (uint16);

30:     function getSwapperProgressionUpperBound() external view returns (uint256);

34:     function getSwapperBonusRewardrate() external view returns (uint16);

38:     function setSwapperBonusRateUser(address user_, bool getsBonusRate_) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IRewardManager.sol)

```solidity
File: src/interfaces/IStrategy.sol

12:     function getAvailableAssetsForWithdrawal() external view returns (uint256);

14:     function isProtectStrategy() external returns (bool);

16:     function harvestRewards(bytes memory) external returns (ReturnedRewards[] memory);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IStrategy.sol)

```solidity
File: src/interfaces/ISwapper.sol

5:     function swapTokensForReward(address ctAssetToken_, address rewardToken_, uint256 ctAssetAmount_) external;

13:     function getRewardManager() external view returns (address);

15:     function getTreasury() external view returns (address);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/ISwapper.sol)

```solidity
File: src/interfaces/ITokenRegistry.sol

25:     function removeToken(address tokenAddress_) external;

29:     function unregisterToken(address tokenAddress_) external;

46:     function updateIsReward(address tokenAddress_, bool isReward_) external;

51:     function getOracle(address tokenAddress_) external view returns (OracleInformation memory);

56:     function isRegistered(address tokenAddress_) external view returns (bool);

61:     function isRewardToken(address tokenAddress_) external view returns (bool);

65:     function getTokens() external view returns (address[] memory);

70:     function getSubsetOfTokens(TokenFilterTypes subset) external view returns (address[] memory);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/ITokenRegistry.sol)

```solidity
File: src/interfaces/IVaultDeploymentManager.sol

7:     function addImplementation(bytes32 id_, ImplementationData calldata implementation_) external;

8:     function removeImplementation(bytes32 id_) external;

9:     function deployNewVault(bytes32 id_, bytes calldata data_) external returns (address);

10:     function removeVault(address vault_, bytes32 vaultId_) external;

11:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external;

12:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IVaultDeploymentManager.sol)

```solidity
File: src/interfaces/IVaultRegistry.sol

5:     function addVault(address vault_, bytes32 vaultId_) external;

6:     function removeVault(address vault_, bytes32 vaultId_) external;

7:     function getAllVaults() external view returns (address[] memory);

8:     function getVaultsByImplementationId(bytes32 id_) external view returns (address[] memory);

9:     function getVaultsByToken(address asset) external view returns (address[] memory);

10:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external;

11:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IVaultRegistry.sol)

```solidity
File: src/interfaces/IWithdrawalQueue.sol

5:     function requestWithdrawal(address recipient, uint256 amount) external;

11:     function unfinalizedAmount() external view returns (uint256);

12:     function getLastFinalizedRequestId() external view returns (uint256);

13:     function getLastRequestId() external view returns (uint256);

15:     function _finalize(uint256 _lastRequestIdToBeFinalized) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IWithdrawalQueue.sol)

```solidity
File: src/managers/DeploymentManager.sol

42:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

49:     function removeImplementation(bytes32 id_) external onlyOwner {

58:     function deployNewVault(bytes32 id_, bytes calldata data_) external onlyOwner returns (address newVaultAddress) {

75:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

83:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {

89:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

79:     function setSwapperBaseRewardrate(uint16 baseRewardrate_) external onlyOwner {

88:     function setSwapperMaxProgressionFactor(uint16 maxProgressionFactor_) external onlyOwner {

97:     function setSwapperProgressionUpperBound(uint256 progressionUpperBound_) external onlyOwner {

105:     function setSwapperBonusRewardrateForUser(uint16 bonusRewardrateForUser_) external onlyOwner {

114:     function setSwapperBonusRewardrateForCtToken(uint16 bonusRewardrateForCtToken_) external onlyOwner {

123:     function setSwapperBonusRewardrateForSwapToken(uint16 bonusRewardrateForSwapToken_) external onlyOwner {

173:     function enableSwapperBonusRateForUser(address user_, bool enableBonusRate_) external onlyOwner {

182:     function enableSwapperBonusRateForRewardToken(address rewardToken_, bool enableBonusRate_) external onlyOwner {

191:     function enableSwapperBonusRateForCtToken(address ctAssetToken_, bool enableBonusRate_) external onlyOwner {

200:     function getSwapperBaseRewardrate() external view returns (uint256) {

206:     function getMaxProgressionFactor() external view returns (uint256) {

212:     function getSwapperProgressionUpperBound() external view returns (uint256) {

218:     function getSwapperBonusRewardrateForUser() external view returns (uint256) {

224:     function getSwapperBonusRewardrateForCtToken() external view returns (uint256) {

230:     function getSwapperBonusRewardrateForSwapToken() external view returns (uint256) {

284:     function swapperBonusRateForUser(address user_) external view returns (bool) {

292:     function swapperBonusRateForRewardToken(address rewardToken_) external view returns (bool) {

299:     function swapperBonusRateForCtToken(address ctAssetToken_) external view returns (bool) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/managers/VaultManager.sol

39:     function pauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

43:     function unpauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

47:     function pauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

61:     function unpauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

91:     function removeImplementation(bytes32 id_) external onlyRole(VAULT_MANAGER_ROLE) {

95:     function removeVault(address vault_, bytes32 vaultId_) external onlyRole(VAULT_MANAGER_ROLE) {

99:     function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {

103:     function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {

107:     function toggleIdleVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

120:     function removeStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

133:     function pushFundsToStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

137:     function pushFundsToSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

149:     function pullFundsFromSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

153:     function pullFundsFromStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

157:     function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {

161:     function batchClaimWithdrawal(address vault_, uint256 maxRequests) external onlyRole(VAULT_MANAGER_ROLE) {

165:     function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

85:     function getWithdrawalRequests(address _owner) external view virtual returns (uint256[] memory requestIds) {

91:     function getLastRequestId() public view virtual returns (uint256) {

97:     function getLastFinalizedRequestId() public view virtual returns (uint256) {

102:     function unfinalizedRequestNumber() public view virtual returns (uint256) {

109:     function unfinalizedAmount() external view virtual onlyOwner returns (uint256) {

114:     function _getStatus(uint256 _requestId) internal view virtual returns (WithdrawalRequestStatus memory status) {

131:     function requestWithdrawal(address recipient, uint256 amount) external virtual onlyOwner {

185:     function _finalize(uint256 _lastRequestIdToBeFinalized) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

35:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

50:     function removeImplementation(bytes32 id_) external onlyOwner {

78:     function getImplementation(bytes32 id_) external view returns (ImplementationData memory) {

84:     function getHistoricalImplementationAddresses() external view returns (address[] memory) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

111:     function updateIsReward(address tokenAddress_, bool isReward_) external override(ITokenRegistry) onlyOwner {

133:     function isRegistered(address tokenAddress_) public view returns (bool) {

140:     function isRewardToken(address tokenAddress_) public view returns (bool) {

145:     function getTokens() public view override(ITokenRegistry) returns (address[] memory) {

186:     function getTreasury() public view returns (address) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

46:     function addVault(address vault_, bytes32 vaultId_) external override onlyOwner {

68:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

77:     function getAllVaults() external view returns (address[] memory) {

84:     function getVaultsByImplementationId(bytes32 id_) external view returns (address[] memory) {

88:     function getVaultsByToken(address asset) external view virtual returns (address[] memory vaults) {

92:     function _handleRemoveVault(address vault_, address[] storage vaultArray_) internal {

116:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {

122:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

58:     function isProtectStrategy() external pure returns (bool) {

62:     function getAvailableAssetsForWithdrawal() external view returns (uint256) {

70:     function _totalAssets() internal view override returns (uint256) {

78:     function getRewardTokenAddresses() public view override returns (address[] memory) {

86:     function _protocolDeposit(uint256 assets_, uint256) internal virtual override {

94:     function _protocolWithdraw(uint256 assets_, uint256) internal virtual override {

103:     function _handleRewardsOnWithdraw() internal override {

116:     function _getRewardsToStrategy(bytes memory) internal override {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/Aave/IAaveV3.sol

15:     function scaledBalanceOf(address user) external view returns (uint256);

22:     function scaledTotalSupply() external view returns (uint256);

32:     function UNDERLYING_ASSET_ADDRESS() external view returns (address);

38:     function getIncentivesController() external view returns (IAaveIncentives);

50:     function getRewardsByAsset(address asset) external view returns (address[] memory);

56:     function getRewardsList() external view returns (address[] memory);

74:     function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

76:     function withdraw(address asset, uint256 amount, address to) external returns (uint256);

78:     function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

98:     function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

108:     function getReserveData(address asset) external view returns (DataTypes.ReserveData2 memory);

110:     function getReserveNormalizedIncome(address asset) external view returns (uint256);

141:     function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

144:     function POOL() external view returns (ILendingPool);

157:     function getMarketId() external view returns (string memory);

165:     function setMarketId(string calldata newMarketId) external;

174:     function getAddress(bytes32 id) external view returns (address);

185:     function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

193:     function setAddress(bytes32 id, address newAddress) external;

199:     function getPool() external view returns (address);

206:     function setPoolImpl(address newPoolImpl) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/IAaveV3.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

62:     function isProtectStrategy() external pure returns (bool) {

66:     function highWatermark() external view returns (uint256) {

82:     function getAvailableAssetsForWithdrawal() public view returns (uint256) {

89:     function setClaimRouter(address claimRouter_) external onlyOwner {

99:     function _totalAssets() internal view override returns (uint256) {

108:     function getBorrowDebt() external view returns (uint256) {

117:     function updateBorrowDebt(uint256 amount) external override onlyClaimRouter {

131:     function executeBorrowClaim(uint256 amount, address recipient) external override onlyClaimRouter {

150:     function _requestFromVault(uint256 amount_) private {

154:     function _handleRewardsOnWithdraw() internal override {}

155:     function _getRewardsToStrategy(bytes memory) internal override {}

156:     function getRewardTokenAddresses() public view override returns (address[] memory _rewardTokens) {}

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/IRadiantV2.sol

9:     function getLendingPool() external view returns (address);

25:     function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

39:     function withdraw(address asset, uint256 amount, address to) external returns (uint256);

41:     function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

52:     function scaledBalanceOf(address user) external view returns (uint256);

59:     function scaledTotalSupply() external view returns (uint256);

68:     function UNDERLYING_ASSET_ADDRESS() external view returns (address);

74:     function getIncentivesController() external view returns (IChefIncentivesController);

81:     function rdntToken() external view returns (address);

82:     function claimableReward(address _user, address[] calldata _tokens) external view returns (uint256[] memory);

83:     function claim(address _user, address[] calldata _tokens) external;

84:     function setClaimReceiver(address _user, address _receiver) external;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/IRadiantV2.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

65:     function isProtectStrategy() external pure returns (bool) {

69:     function getAvailableAssetsForWithdrawal() external view returns (uint256) {

77:     function _totalAssets() internal view override returns (uint256) {

85:     function getRewardTokenAddresses() public view override returns (address[] memory) {

96:     function _protocolDeposit(uint256 amount_, uint256) internal virtual override {

104:     function _protocolWithdraw(uint256 amount_, uint256) internal virtual override {

113:     function _handleRewardsOnWithdraw() internal override {

129:     function _getRewardsToStrategy(bytes memory) internal override {

144:     function setEnableRewards(bool _rewardsEnabled) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

10:     function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {

50:     function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {

104:     function sum(uint256[] memory _numbers) internal pure returns (uint256 s) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/IBaseSiloV1.sol

27:     function siloRepository() external view returns (IERC20);

32:     function assetStorage(address _asset) external view returns (AssetStorage memory);

36:     function getAssets() external view returns (address[] memory assets);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/IBaseSiloV1.sol)

```solidity
File: src/strategies/Silo/ISiloV1.sol

7:     function getSilo(address _asset) external view returns (address);

11:     function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

12:     function claimRewardsToSelf(address[] calldata assets, uint256 amount) external returns (uint256);

13:     function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

14:     function getUserUnclaimedRewards(address user) external view returns (uint256);

16:     function REWARD_TOKEN() external view returns (address);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/ISiloV1.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

108:     function isProtectStrategy() external pure returns (bool) {

112:     function getAvailableAssetsForWithdrawal() external view returns (uint256) {

122:     function _totalAssets() internal view override returns (uint256) {

132:     function getRewardTokenAddresses() public view override returns (address[] memory) {

142:     function _protocolDeposit(uint256 amount_, uint256) internal virtual override {

151:     function _protocolWithdraw(uint256 amount_, uint256) internal virtual override {

160:     function _handleRewardsOnWithdraw() internal override {

177:     function _getRewardsToStrategy(bytes memory) internal override {

188:     function balanceOfUnderlying(uint256 shares) public view returns (uint256) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

178:     function totalAssets() public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {

191:     function addRewardToken(RewardToken calldata rewardToken_) external onlyOwner nonReentrant {

217:     function removeRewardToken(RewardToken calldata rewardToken_) external onlyOwner {

236:     function modifyRewardFeeForRewardToken(uint256 newFee_, RewardToken calldata rewardToken_) external onlyOwner {

254:     function _handleRewardsOnWithdraw() internal virtual;

261:     function setFeeRecipient(address feeRecipient_) external onlyOwner {

273:     function setDepositLimit(uint256 depositLimit_) external onlyOwner {

293:     function getRewardTokens() external view returns (RewardToken[] memory) {

305:     function _getIndex(address token_) internal view returns (uint256 index) {

323:     function _getRewardTokens(uint256 rewardFee_) internal view returns (RewardToken[] memory) {

369:     function getRewardTokenAddresses() public view virtual returns (address[] memory) {

381:     function _protocolDeposit(uint256 assets, uint256 shares) internal virtual {}

382:     function _protocolWithdraw(uint256 assets, uint256 shares) internal virtual {}

383:     function _totalAssets() internal view virtual returns (uint256);

384:     function _getRewardsToStrategy(bytes memory data) internal virtual;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

65:     function isProtectStrategy() external pure returns (bool) {

69:     function getAvailableAssetsForWithdrawal() external view returns (uint256) {

75:     function _totalAssets() internal view override returns (uint256) {

81:     function getRewardTokenAddresses() public view override returns (address[] memory _rewardTokens) {

89:     function _protocolDeposit(uint256 amount_, uint256) internal virtual override {

96:     function _protocolWithdraw(uint256 amount_, uint256) internal virtual override {

101:     function _getRewardsToStrategy(bytes memory) internal override {

109:     function _handleRewardsOnWithdraw() internal override {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/strategies/compoundV3/ICompoundV3.sol

11:     function baseTrackingBorrowSpeed() external view returns (uint256);

13:     function baseTrackingSupplySpeed() external view returns (uint256);

15:     function balanceOf(address _user) external view returns (uint256);

17:     function governor() external view returns (address);

19:     function isSupplyPaused() external view returns (bool);

21:     function supply(address _asset, uint256 _amount) external;

23:     function isWithdrawPaused() external view returns (bool);

25:     function withdraw(address _asset, uint256 _amount) external;

27:     function baseToken() external view returns (address);

31:     function claim(address _cToken, address _owner, bool _accrue) external;

32:     function rewardConfig(address) external view returns (RewardConfig memory);

78:     function getConfiguration(address cometProxy) external view returns (Configuration memory);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/ICompoundV3.sol)

```solidity
File: src/swapper/OraclePlug.sol

40:     function _convertFromTokenToStable(address token_, uint256 tokenAmount_) internal view returns (uint256) {

69:     function _convertFromStableToToken(address token_, uint256 stableAmount_) internal view returns (uint256) {

102:     function getTokenRegistry() public view returns (address) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

105:     function setRewardManager(address rewardManager_) external onlyOwner {

113:     function disableTokenForSwap(address token_, bool disableSwap_) external onlyOwner {

149:     function tokenAvailableForWithdrawal(address rewardToken_) public view returns (bool) {

158:     function amountAvailableForWithdrawal(address rewardToken_, uint256 rewardAmount) public view returns (bool) {

169:     function getRewardManager() public view returns (address) {

175:     function getTreasury() public view returns (address) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

186:     function decimals() public view override returns (uint8) {

213:     function deposit(uint256 assets_) external returns (uint256) {

276:     function mint(uint256 shares_) external returns (uint256) {

338:     function redeem(uint256 shares_) external returns (uint256) {

373:     function withdraw(uint256 assets_) external returns (uint256) {

419:     function _withdraw(uint256 assets_, address receiver_, address owner_, uint256 shares, uint256 feeShares) private {

444:     function _withdrawStrategyFunds(uint256 amount_, address receiver_) private {

495:     function claimWithdrawal(uint256 _requestId, uint256 avaliableAssets) private returns (uint256) {

507:     function getRewardTokens() public view returns (address[] memory) {

511:     function getAvailableAssetsForWithdrawal() public view returns (uint256 totalAvailable) {

532:     function getUserRewards(address userAddress) external view returns (ReturnedRewards[] memory) {

552:     function getTotalRewardsClaimed(address userAddress) external view returns (ReturnedRewards[] memory) {

573:     function totalAssets() public view override returns (uint256 total) {

600:     function previewDeposit(uint256 assets_) public view override returns (uint256) {

616:     function previewMint(uint256 shares_) public view override returns (uint256) {

627:     function previewWithdraw(uint256 assets_) public view override returns (uint256 shares) {

640:     function previewRedeem(uint256 shares_) public view override returns (uint256) {

657:     function maxMint(address) public view override returns (uint256) {

668:     function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256 shares) {

679:     function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual override returns (uint256) {

689:     function accruedProtocolFee() public view returns (uint256) {

711:     function accruedPerformanceFee() public view returns (uint256 fee) {

725:     function getVaultFees() public view returns (VaultFees memory) {

735:     function takePortfolioAndProtocolFees() external nonReentrant takeFees {

744:     function setVaultFees(VaultFees calldata newFees_) external takeFees onlyOwner {

754:     function setFeeRecipient(address newRecipient_) external onlyOwner {

769:     function setWithdrawalQueue(address withdrawalQueue_) external onlyOwner {

787:     function getStrategies() external view returns (Strategy[] memory) {

837:     function removeStrategy(uint256 index_) external nonReentrant onlyOwner takeFees {

852:     function _update(address from, address to, uint256 value) internal override {

895:     function pushFundsToStrategies() public onlyOwner {

910:     function pullFundsFromStrategies() public onlyOwner {

930:     function pullFundsFromSingleStrategy(uint256 index_) public onlyOwner {

945:     function pushFundsIntoSingleStrategy(uint256 index_) external onlyOwner {

965:     function pushFundsIntoSingleStrategy(uint256 index_, uint256 amount) external onlyOwner {

978:     function setDepositLimit(uint256 newLimit_) external onlyOwner {

989:     function harvestRewards(bytes memory encodedData) external onlyOwner nonReentrant {

1033:     function updateUserRewardsToCurrent(address userAddress) private {

1059:     function batchClaimWithdrawal(uint256 maxRequests) external onlyOwner nonReentrant {

1098:     function requestFunds(uint256 amount) external onlyProtect {

1112:     function _validateAndUpdateDepositTimestamps(address receiver_) private {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-17"></a>[NC-17] Interfaces should be defined in separate files from their usage

The interfaces below should be defined in separate files, so that it's easier for future projects to import them, and to avoid duplication later on if they need to be used elsewhere in the project

*Instances (19)*:

```solidity
File: src/strategies/Aave/IAaveV3.sol

7: interface IScaledBalanceToken {

26: interface IAToken is IERC20, IScaledBalanceToken {

45: interface IAaveIncentives {

73: interface ILendingPool {

114: interface IProtocolDataProvider {

120: interface IFlashLoanReceiver {

152: interface IPoolAddressesProvider {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/IAaveV3.sol)

```solidity
File: src/strategies/Radiant/IRadiantV2.sol

8: interface ILendingPoolAddressesProvider {

12: interface ILendingPool {

44: interface IScaledBalanceToken {

62: interface IAToken is IERC20, IScaledBalanceToken {

80: interface IChefIncentivesController {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/IRadiantV2.sol)

```solidity
File: src/strategies/Silo/ISiloV1.sol

6: interface ISiloRepository {

10: interface ISiloIncentivesController {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/ISiloV1.sol)

```solidity
File: src/strategies/compoundV3/ICompoundV3.sol

10: interface ICToken {

30: interface ICometRewarder {

35: interface IGovernor {

39: interface IAdmin {

43: interface ICometConfigurator {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/ICompoundV3.sol)

### <a name="NC-18"></a>[NC-18] Lack of checks in setters

Be it sanity checks (like checks against `0`-values) or initial setting checks: it's best for Setter functions to have them

*Instances (14)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {
            delete tokenCascade;
            _setTokenCascade(tokenCascade_);
            emit TokenCascadeUpdated();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/DeploymentManager.sol

83:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {
            vaultRegistry.setVaultByTokenLimit(vaultByTokenLimit_);

89:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {
            vaultRegistry.setTotalVaultsAllowed(totalVaultsAllowed_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

97:     function setSwapperProgressionUpperBound(uint256 progressionUpperBound_) external onlyOwner {
            _swapperRewards.progressionUpperBound = SafeCast.toUint176(progressionUpperBound_);
            emit SwapperProgressionUpperBoundUpdated(progressionUpperBound_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/managers/VaultManager.sol

99:     function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {
            IConcreteMultiStrategyVault(vault_).setVaultFees(fees_);

103:     function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {
             IConcreteMultiStrategyVault(vault_).setFeeRecipient(newRecipient_);

157:     function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {
             IConcreteMultiStrategyVault(vault_).setDepositLimit(limit_);

165:     function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {
             IConcreteMultiStrategyVault(vault_).setWithdrawalQueue(withdrawalQueue_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

93:     function updateOracle(
            address tokenAddress_,
            address oracleAddr_,
            uint8 oracleDecimals_,
            string memory oraclePair_
        ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {
            _token[tokenAddress_].oracle = OracleInformation({
                addr: oracleAddr_,
                decimals: oracleDecimals_,
                pair: oraclePair_
            });
    
            emit OracleUpdated(tokenAddress_, oracleAddr_, oracleDecimals_, oraclePair_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

116:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {
             vaultByTokenLimit = vaultByTokenLimit_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

144:     function setEnableRewards(bool _rewardsEnabled) external onlyOwner {
             rewardsEnabled = _rewardsEnabled;
             emit SetEnableRewards(msg.sender, _rewardsEnabled);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/swapper/Swapper.sol

105:     function setRewardManager(address rewardManager_) external onlyOwner {
             _rewardManager = IRewardManager(rewardManager_);
             emit RewardManagerUpdated(rewardManager_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

744:     function setVaultFees(VaultFees calldata newFees_) external takeFees onlyOwner {
             fees = newFees_; // Update the fee structure
             feesUpdatedAt = block.timestamp; // Record the time of the fee update

978:     function setDepositLimit(uint256 newLimit_) external onlyOwner {
             depositLimit = newLimit_;
             emit DepositLimitSet(newLimit_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-19"></a>[NC-19] Missing Event for critical parameters change

Events help non-contract tools to track changes, and events prevent users from being surprised by changes.

*Instances (11)*:

```solidity
File: src/managers/DeploymentManager.sol

83:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {
            vaultRegistry.setVaultByTokenLimit(vaultByTokenLimit_);

89:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {
            vaultRegistry.setTotalVaultsAllowed(totalVaultsAllowed_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/VaultManager.sol

99:     function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {
            IConcreteMultiStrategyVault(vault_).setVaultFees(fees_);

103:     function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {
             IConcreteMultiStrategyVault(vault_).setFeeRecipient(newRecipient_);

157:     function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {
             IConcreteMultiStrategyVault(vault_).setDepositLimit(limit_);

165:     function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {
             IConcreteMultiStrategyVault(vault_).setWithdrawalQueue(withdrawalQueue_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/registries/VaultRegistry.sol

116:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {
             vaultByTokenLimit = vaultByTokenLimit_;

122:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {
             if (totalVaultsAllowed_ < allVaultsCreated.length) revert TotalVaultsAllowedExceeded(allVaultsCreated.length);
             totalVaultsAllowed = totalVaultsAllowed_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/StrategyBase.sol

261:     function setFeeRecipient(address feeRecipient_) external onlyOwner {
             if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();
             feeRecipient = feeRecipient_;

273:     function setDepositLimit(uint256 depositLimit_) external onlyOwner {
             if (depositLimit_ == 0) revert InvalidDepositLimit();
             depositLimit = depositLimit_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

744:     function setVaultFees(VaultFees calldata newFees_) external takeFees onlyOwner {
             fees = newFees_; // Update the fee structure
             feesUpdatedAt = block.timestamp; // Record the time of the fee update

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-20"></a>[NC-20] NatSpec is completely non-existent on functions that should have them

Public and external functions that aren't view or pure should have NatSpec comments

*Instances (26)*:

```solidity
File: src/managers/DeploymentManager.sol

75:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/VaultManager.sol

26:     function adminSetup(

39:     function pauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

43:     function unpauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

47:     function pauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

61:     function unpauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

75:     function deployNewVault(

84:     function registerNewImplementation(

91:     function removeImplementation(bytes32 id_) external onlyRole(VAULT_MANAGER_ROLE) {

95:     function removeVault(address vault_, bytes32 vaultId_) external onlyRole(VAULT_MANAGER_ROLE) {

99:     function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {

103:     function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {

107:     function toggleIdleVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

111:     function addReplaceStrategy(

120:     function removeStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

125:     function changeStrategyAllocations(

133:     function pushFundsToStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

137:     function pushFundsToSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

141:     function pushFundsToSingleStrategy(

149:     function pullFundsFromSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

153:     function pullFundsFromStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

157:     function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {

161:     function batchClaimWithdrawal(address vault_, uint256 maxRequests) external onlyRole(VAULT_MANAGER_ROLE) {

165:     function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/registries/VaultRegistry.sol

68:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

1086:     function claimRewards() external {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-21"></a>[NC-21] Incomplete NatSpec: `@param` is missing on actually documented functions

The following functions are missing `@param` NatSpec comments.

*Instances (6)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

181:     /// @notice Function to request assets from the vault.
         /// @dev Requests assets from the vault and executes a borrow claim through the protection strategy.
         /// @param tokenAddress The address of the token.
         /// @param amount_ The amount of assets to request.
         /// @param userBlueprint The address of the user's blueprint contract.
         function requestToken(
             VaultFlags,
             address tokenAddress,
             uint256 amount_,
             address payable userBlueprint

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/factories/VaultFactory.sol

23:     /// @notice Deploys a new vault using a specified implementation.
        /// @param implementation_ The implementation data including the address and whether initialization data is required.
        /// @param data_ The initialization data to be passed to the new vault, if required.
        /// @return newVault The address of the newly deployed vault.
        /// @dev Only callable by the contract owner.
        function deployVault(
            ImplementationData calldata implementation_,
            bytes calldata data_,
            bytes32 salt_

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

149:     /// @dev preapares a request to be transferred
         ///  Emits WithdrawalClaimed event
         //TODO test this function
         //slither-disable-next-line naming-convention
         function prepareWithdrawal(
             uint256 _requestId,
             uint256 _avaliableAssets

182:     /// @dev Finalize requests in the queue
         ///  Emits WithdrawalsFinalized event.
         //slither-disable-next-line naming-convention
         function _finalize(uint256 _lastRequestIdToBeFinalized) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

139:     /**
          * @dev by setting rewardsEnabled to true the strategy will be able to handle rdnt rewards.
          * check the eligibility criteria before enabling rewards here:
          * https://docs.radiant.capital/radiant/project-info/dlp/eligibility
          */
         function setEnableRewards(bool _rewardsEnabled) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

983:     /**
          * @notice Harvest rewards on every strategy.
          * @dev Calculates de reward index for each reward found.
          */
         //we control the external call
         //slither-disable-next-line unused-return,calls-loop,reentrancy-no-eth
         function harvestRewards(bytes memory encodedData) external onlyOwner nonReentrant {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-22"></a>[NC-22] Incomplete NatSpec: `@return` is missing on actually documented functions

The following functions are missing `@return` NatSpec comments.

*Instances (2)*:

```solidity
File: src/managers/DeploymentManager.sol

53:     /// @notice Deploys a new vault using a specified implementation.
        /// @param id_ The unique identifier for the implementation to use for the new vault.
        /// @param data_ The initialization data to be passed to the new vault.
        /// @dev Only callable by the contract owner.
        /// @dev Reverts if the specified implementation does not exist.
        function deployNewVault(bytes32 id_, bytes calldata data_) external onlyOwner returns (address newVaultAddress) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

149:     /// @dev preapares a request to be transferred
         ///  Emits WithdrawalClaimed event
         //TODO test this function
         //slither-disable-next-line naming-convention
         function prepareWithdrawal(
             uint256 _requestId,
             uint256 _avaliableAssets
         ) external onlyOwner returns (address recipient, uint256 amount, uint256 avaliableAssets) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

### <a name="NC-23"></a>[NC-23] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor

If a function is supposed to be access-controlled, a `modifier` should be used instead of a `require/if` statement for more readability.

*Instances (2)*:

```solidity
File: src/strategies/StrategyBase.sol

54:         if (msg.sender != _vault) revert OnlyVault(msg.sender);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

420:         if (msg.sender != owner_) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-24"></a>[NC-24] Consider using named mappings

Consider moving to solidity version 0.8.18 or later, and using [named mappings](https://ethereum.stackexchange.com/questions/51629/how-to-name-the-arguments-in-mapping/145555#145555) to make it easier to understand the purpose of each mapping

*Instances (15)*:

```solidity
File: src/managers/RewardManager.sol

38:     mapping(address => bool) internal _swapperGetsBonusRate;

39:     mapping(address => bool) internal _swappedRewardTokenGetsBonusRate;

40:     mapping(address => bool) internal _swappedCtTokenGetsBonusRate;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

19:     mapping(address => EnumerableSet.UintSet) private _requestsByOwner;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

15:     mapping(bytes32 => ImplementationData) private _implementations;

18:     mapping(bytes32 => bool) public implementationExists;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

27:     mapping(address => TokenInformation) private _token;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

21:     mapping(address => bool) public vaultExists;

24:     mapping(bytes32 => address[]) public vaultIdToAddressArray;

30:     mapping(address => EnumerableSet.AddressSet) private vaultsByToken;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/StrategyBase.sol

49:     mapping(address => bool) public rewardTokenApproved;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/Swapper.sol

52:     mapping(address => bool) internal _unavailableForWithdrawal;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

80:     mapping(address => uint256) public rewardIndex;

83:     mapping(address => mapping(address => uint256)) public userRewardIndex;

86:     mapping(address => mapping(address => uint256)) public totalRewardsClaimed;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-25"></a>[NC-25] Owner can renounce while system is paused

The contract owner or single user with a role is not prevented from renouncing the role/ownership while the contract is paused, which would cause any user assets stored in the protocol, to be locked indefinitely.

*Instances (2)*:

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

194:     function pause() public onlyOwner {

202:     function unpause() public onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-26"></a>[NC-26] Adding a `return` statement when the function defines a named return variable, is redundant

*Instances (10)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

336:     /// @notice Function to calculate the total borrow debt for a specific token across all vaults.
         /// @dev Calculates the total borrow debt by summing the borrow debts from all vaults associated with the token.
         /// @param tokenAddress The address of the token.
         /// @return data The total borrow debt for the token.
         function _getTokenTotalBorrowDebt(address tokenAddress) private view returns (DebtVaults memory data) {
             address[] memory vaults = vaultRegistry.getVaultsByToken(tokenAddress);
             data.vaultsWithProtect = 0;
             uint256 len = vaults.length;
             data.totalBorrowDebt = 0;
             for (uint256 i; i < len; ) {
                 IConcreteMultiStrategyVault currentVault = IConcreteMultiStrategyVault(vaults[i]);
                 address protectionStrat = currentVault.protectStrategy();
                 if (protectionStrat != address(0x0)) {
                     data.vaultsWithProtect++;
                     data.totalBorrowDebt += IProtectStrategy(protectionStrat).getBorrowDebt();
                 }
                 unchecked {
                     i++;
                 }
             }
             return data;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

85:     function getWithdrawalRequests(address _owner) external view virtual returns (uint256[] memory requestIds) {
            return _requestsByOwner[_owner].values();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/VaultRegistry.sol

88:     function getVaultsByToken(address asset) external view virtual returns (address[] memory vaults) {
            return vaultsByToken[asset].values();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

10:     function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {
            if (totalShares == 0 || totalAmount == 0) {
                return amount;

27:     function toShareRoundUp(
            uint256 amount,
            uint256 totalAmount,
            uint256 totalShares
        ) internal pure returns (uint256 result) {
            if (totalShares == 0 || totalAmount == 0) {
                return amount;

50:     function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {
            if (totalShares == 0 || totalAmount == 0) {
                return 0;

67:     function toAmountRoundUp(
            uint256 share,
            uint256 totalAmount,
            uint256 totalShares
        ) internal pure returns (uint256 result) {
            if (totalShares == 0 || totalAmount == 0) {
                return 0;

113:     /// @notice Calculates fraction between borrowed and deposited amount of tokens denominated in percentage
         /// @dev It assumes `_dp` = 100%.
         /// @param _dp decimal points used by model
         /// @param _totalDeposits current total deposits for assets
         /// @param _totalBorrowAmount current total borrows for assets
         /// @return utilization value, capped to 100%
         /// Limiting utilisation ratio by 100% max will allows us to perform better interest rate computations
         /// and should not affect any other part of protocol.
         //slither-disable-next-line naming-convention
         function calculateUtilization(
             uint256 _dp,
             uint256 _totalDeposits,
             uint256 _totalBorrowAmount
         ) internal pure returns (uint256 utilization) {
             if (_totalDeposits == 0 || _totalBorrowAmount == 0) return 0;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/swapper/Swapper.sol

119:     /// @notice Previews the swap of ctAsset tokens for reward tokens
         /// @param ctAssetToken_ The address of the ctAsset token
         /// @param rewardToken_ The address of the reward token
         /// @param ctAssetAmount_ The amount of ctAsset tokens to swap
         /// @return rewardAmount The amount of reward tokens
         /// @return availableForWithdrawal A boolean indicating if the reward token is available for withdrawal
         /// @return isRewardToken A boolean indicating if the reward token is a valid reward token
         /// @dev The function checks if the token is registered and whether its a valid reward token
         function previewSwapTokensForReward(
             address ctAssetToken_,
             address rewardToken_,
             uint256 ctAssetAmount_
         ) public view returns (uint256 rewardAmount, bool availableForWithdrawal, bool isRewardToken) {
             // If token is not registered, one cannot use the oracle to get the price
             if (!_tokenRegistry.isRegistered(rewardToken_)) return (0, false, false);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

511:     function getAvailableAssetsForWithdrawal() public view returns (uint256 totalAvailable) {
             totalAvailable = IERC20(asset()).balanceOf(address(this));
             uint256 len = strategies.length;
             for (uint256 i; i < len; ) {
                 Strategy memory strategy = strategies[i];
                 //We control both the length of the array and the external call
                 //slither-disable-next-line calls-loop
                 totalAvailable += strategy.strategy.getAvailableAssetsForWithdrawal();
                 unchecked {
                     i++;
                 }
             }
             return totalAvailable;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-27"></a>[NC-27] `require()` / `revert()` statements should have descriptive reason strings

*Instances (27)*:

```solidity
File: src/managers/RewardManager.sol

60:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

61:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

62:         if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

63:         if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

64:         if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

80:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

89:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

106:         if (bonusRewardrateForUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

115:         if (bonusRewardrateForCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

124:         if (bonusRewardrateForSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

145:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

146:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

147:         if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

148:         if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

149:         if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

174:         if (user_ == address(0)) revert Errors.InvalidUserAddress();

285:         if (!(owner() == _msgSender() || user_ == _msgSender())) revert Errors.InvalidUserAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

32:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

52:         if (isRegistered(tokenAddress_)) revert Errors.TokenAlreadyRegistered(tokenAddress_);

62:         if (!_listedTokens.add(tokenAddress_)) revert Errors.AdditionFail();

75:         if (!_listedTokens.remove(tokenAddress_)) revert Errors.RemoveFail();

113:             revert Errors.UnregisteredTokensCannotBeRewards(tokenAddress_); // check if token is registered

195:         if (!isRegistered(tokenAddress_)) revert Errors.TokenNotRegistered(tokenAddress_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/swapper/OraclePlug.sol

22:         if (tokenRegistry_ == address(0)) revert Errors.InvalidTokenRegistry();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

66:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

83:         if (!_tokenRegistry.isRewardToken(rewardToken_)) revert Errors.NotValidRewardToken(rewardToken_);

88:             revert Errors.NotAvailableForWithdrawal(rewardToken_, rewardAmount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="NC-28"></a>[NC-28] Take advantage of Custom Error's return value property

An important feature of Custom Error is that values such as address, tokenID, msg.value can be written inside the () sign, this kind of approach provides a serious advantage in debugging and examining the revert details of dapps such as tenderly.

*Instances (86)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

67:         if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();

68:         if (owner == address(0)) revert InvalidDefaultAdminAddress();

87:         if (vaultRegistry_ == address(0)) revert InvalidVaultRegistry();

110:                 revert InvalidAssetAddress();

222:             revert NoProtectionStrategiesFound();

259:         if (amount_ == 0) revert ZeroAmount();

264:         if (debtVaults.vaultsWithProtect == 0) revert NoProtectionStrategiesFound();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/factories/VaultFactory.sol

45:                 revert VaultDeployInitFailed();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/managers/RewardManager.sol

60:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

61:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

62:         if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

63:         if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

64:         if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

80:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

89:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

106:         if (bonusRewardrateForUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

115:         if (bonusRewardrateForCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

124:         if (bonusRewardrateForSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

145:         if (baseRewardrate_ > BASISPOINTS) revert Errors.SwapperBaseRewardrate();

146:         if (maxProgressionFactor_ > BASISPOINTS) revert Errors.SwapperMaxProgressionFactor();

147:         if (bonusRewardrateUser_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateUser();

148:         if (bonusRewardrateCtToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateCtToken();

149:         if (bonusRewardrateSwapToken_ > BASISPOINTS) revert Errors.SwapperBonusRewardrateSwapToken();

174:         if (user_ == address(0)) revert Errors.InvalidUserAddress();

285:         if (!(owner() == _msgSender() || user_ == _msgSender())) revert Errors.InvalidUserAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/registries/TokenRegistry.sol

32:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

62:         if (!_listedTokens.add(tokenAddress_)) revert Errors.AdditionFail();

75:         if (!_listedTokens.remove(tokenAddress_)) revert Errors.RemoveFail();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

47:         if (vault_ == address(0)) revert VaultZeroAddress();

50:             revert VaultAlreadyExists();

63:             revert VaultByTokenLimitExceeded(underlyingAsset, vaultsByToken[underlyingAsset].length());

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

38:             revert AssetDivergence();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

52:             revert ClaimRouterUnauthorizedAccount(_msgSender());

90:         if (claimRouter_ == address(0)) revert InvalidClaimRouterAddress();

118:         if (borrowDebt < amount) revert InvalidSubstraction();

132:         if (amount == 0) revert ZeroAmount();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

37:         if (addressesProvider_ == address(0)) revert ZeroAddress();

45:         if (rToken.UNDERLYING_ASSET_ADDRESS() != address(baseAsset_)) revert AssetDivergence();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

23:             revert ZeroShares();

63:             revert ZeroAssets();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

50:         if (siloRepository_ == address(0)) revert ZeroAddress();

51:         if (siloIncentivesController_ == address(0)) revert ZeroAddress();

55:         if (address(silo) == address(0)) revert ZeroAddress();

68:             if (temp.i == temp.length) revert AssetDivergence();

92:         if (address(collateralToken) == address(0)) revert InvalidAssetAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

91:                     revert InvalidRewardTokenAddress();

94:                     revert AccumulatedFeeAccountedMustBeZero();

98:                 if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();

109:         if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();

113:         if (depositLimit_ == 0) revert InvalidDepositLimit();

135:         if (shares_ == 0 || assets_ == 0) revert ZeroAmount();

163:         if (shares_ == 0 || assets_ == 0) revert ZeroAmount();

194:             revert InvalidRewardTokenAddress();

197:             revert RewardTokenAlreadyApproved();

200:             revert AccumulatedFeeAccountedMustBeZero();

207:             revert ERC20ApproveFail();

220:             revert RewardTokenNotApproved();

239:             revert RewardTokenNotApproved();

262:         if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();

274:         if (depositLimit_ == 0) revert InvalidDepositLimit();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

90:         if (cToken.isSupplyPaused()) revert SupplyPaused();

97:         if (cToken.isWithdrawPaused()) revert WithdrawPaused();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

22:         if (tokenRegistry_ == address(0)) revert Errors.InvalidTokenRegistry();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

66:         if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

98:             revert ProtectUnauthorizedAccount(_msgSender());

156:         if (address(baseAsset_) == address(0)) revert InvalidAssetAddress();

168:             revert InvalidFeeRecipient();

233:         if (assets_ > maxDeposit(receiver_) || assets_ > depositLimit) revert MaxError();

243:         if (shares <= DUST) revert ZeroAmount();

296:         if (shares_ == 0) revert ZeroAmount();

306:         if (assets > maxMint(receiver_)) revert MaxError();

356:         if (receiver_ == address(0)) revert InvalidRecipient();

357:         if (shares_ == 0) revert ZeroAmount();

358:         if (shares_ > maxRedeem(owner_)) revert MaxError();

393:         if (receiver_ == address(0)) revert InvalidRecipient();

394:         if (assets_ > maxWithdraw(owner_)) revert MaxError();

396:         if (shares <= DUST) revert ZeroAmount();

590:         if (total < unfinalized) revert InvalidSubstraction();

756:         if (newRecipient_ == address(0)) revert InvalidFeeRecipient();

771:         if (withdrawalQueue_ == address(0)) revert InvalidWithdrawlQueue();

881:         if (allotmentTotals != 10000) revert AllotmentTotalTooHigh();

896:         if (vaultIdle) revert VaultIsIdle();

950:         if (vaultIdle) revert VaultIsIdle();

968:         if (vaultIdle) revert VaultIsIdle();

1060:         if (address(withdrawalQueue) == address(0)) revert QueueNotSet();

1113:         if (receiver_ == address(0)) revert InvalidRecipient();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-29"></a>[NC-29] Contract does not follow the Solidity style guide's suggested layout ordering

The [style guide](https://docs.soliditylang.org/en/v0.8.16/style-guide.html#order-of-layout) says that, within a contract, the ordering should be:

1) Type declarations
2) State variables
3) Events
4) Modifiers
5) Functions

However, the contract(s) below do not follow this ordering

*Instances (10)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

1: 
   Current order:
   EventDefinition.TokenCascadeUpdated
   EventDefinition.BlueprintRoleGranted
   EventDefinition.VaultRegistryUpdated
   EventDefinition.ClaimRequested
   EventDefinition.Repayment
   EventDefinition.RewardAdded
   EventDefinition.DustCleaned
   UsingForDirective.Math
   UsingForDirective.IERC20
   VariableDeclaration.BLUEPRINT_ROLE
   StructDefinition.DebtVaults
   VariableDeclaration.vaultRegistry
   VariableDeclaration.tokenCascade
   FunctionDefinition.constructor
   FunctionDefinition.setVaultRegistry
   FunctionDefinition.setTokenCascade
   FunctionDefinition._setTokenCascade
   FunctionDefinition._getStrategy
   FunctionDefinition.requestToken
   FunctionDefinition.addRewards
   FunctionDefinition.repay
   FunctionDefinition._addTokensToStrategy
   FunctionDefinition._getTokenTotalBorrowDebt
   FunctionDefinition.getTokenTotalAvaliableForProtection
   
   Suggested order:
   UsingForDirective.Math
   UsingForDirective.IERC20
   VariableDeclaration.BLUEPRINT_ROLE
   VariableDeclaration.vaultRegistry
   VariableDeclaration.tokenCascade
   StructDefinition.DebtVaults
   EventDefinition.TokenCascadeUpdated
   EventDefinition.BlueprintRoleGranted
   EventDefinition.VaultRegistryUpdated
   EventDefinition.ClaimRequested
   EventDefinition.Repayment
   EventDefinition.RewardAdded
   EventDefinition.DustCleaned
   FunctionDefinition.constructor
   FunctionDefinition.setVaultRegistry
   FunctionDefinition.setTokenCascade
   FunctionDefinition._setTokenCascade
   FunctionDefinition._getStrategy
   FunctionDefinition.requestToken
   FunctionDefinition.addRewards
   FunctionDefinition.repay
   FunctionDefinition._addTokensToStrategy
   FunctionDefinition._getTokenTotalBorrowDebt
   FunctionDefinition.getTokenTotalAvaliableForProtection

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/interfaces/IBeraOracle.sol

1: 
   Current order:
   FunctionDefinition.addCurrencyPairs
   FunctionDefinition.getAllCurrencyPairs
   FunctionDefinition.getDecimals
   FunctionDefinition.getPrice
   FunctionDefinition.hasCurrencyPair
   FunctionDefinition.removeCurrencyPairs
   EventDefinition.CurrencyPairsAdded
   EventDefinition.CurrencyPairsRemoved
   
   Suggested order:
   EventDefinition.CurrencyPairsAdded
   EventDefinition.CurrencyPairsRemoved
   FunctionDefinition.addCurrencyPairs
   FunctionDefinition.getAllCurrencyPairs
   FunctionDefinition.getDecimals
   FunctionDefinition.getPrice
   FunctionDefinition.hasCurrencyPair
   FunctionDefinition.removeCurrencyPairs

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IBeraOracle.sol)

```solidity
File: src/managers/RewardManager.sol

1: 
   Current order:
   EventDefinition.SwapperRewardsUpdated
   EventDefinition.SwapperBaseRewardrateUpdated
   EventDefinition.SwapperMaxProgressionFactorUpdated
   EventDefinition.SwapperProgressionUpperBoundUpdated
   EventDefinition.SwapperBonusRewardrateForUserUpdated
   EventDefinition.SwapperBonusRewardrateForCtTokenUpdated
   EventDefinition.SwapperBonusRewardrateForSwapTokenUpdated
   EventDefinition.SwapperBonusRateForRewardTokenEnabled
   EventDefinition.SwapperBonusRateForCtTokenEnabled
   UsingForDirective.Math
   VariableDeclaration._swapperRewards
   VariableDeclaration._swapperGetsBonusRate
   VariableDeclaration._swappedRewardTokenGetsBonusRate
   VariableDeclaration._swappedCtTokenGetsBonusRate
   FunctionDefinition.constructor
   FunctionDefinition.setSwapperBaseRewardrate
   FunctionDefinition.setSwapperMaxProgressionFactor
   FunctionDefinition.setSwapperProgressionUpperBound
   FunctionDefinition.setSwapperBonusRewardrateForUser
   FunctionDefinition.setSwapperBonusRewardrateForCtToken
   FunctionDefinition.setSwapperBonusRewardrateForSwapToken
   FunctionDefinition.setSwapperRewards
   FunctionDefinition.enableSwapperBonusRateForUser
   FunctionDefinition.enableSwapperBonusRateForRewardToken
   FunctionDefinition.enableSwapperBonusRateForCtToken
   FunctionDefinition.getSwapperBaseRewardrate
   FunctionDefinition.getMaxProgressionFactor
   FunctionDefinition.getSwapperProgressionUpperBound
   FunctionDefinition.getSwapperBonusRewardrateForUser
   FunctionDefinition.getSwapperBonusRewardrateForCtToken
   FunctionDefinition.getSwapperBonusRewardrateForSwapToken
   FunctionDefinition.quoteSwapperRewardrate
   FunctionDefinition.swapperBonusRateForUser
   FunctionDefinition.swapperBonusRateForRewardToken
   FunctionDefinition.swapperBonusRateForCtToken
   
   Suggested order:
   UsingForDirective.Math
   VariableDeclaration._swapperRewards
   VariableDeclaration._swapperGetsBonusRate
   VariableDeclaration._swappedRewardTokenGetsBonusRate
   VariableDeclaration._swappedCtTokenGetsBonusRate
   EventDefinition.SwapperRewardsUpdated
   EventDefinition.SwapperBaseRewardrateUpdated
   EventDefinition.SwapperMaxProgressionFactorUpdated
   EventDefinition.SwapperProgressionUpperBoundUpdated
   EventDefinition.SwapperBonusRewardrateForUserUpdated
   EventDefinition.SwapperBonusRewardrateForCtTokenUpdated
   EventDefinition.SwapperBonusRewardrateForSwapTokenUpdated
   EventDefinition.SwapperBonusRateForRewardTokenEnabled
   EventDefinition.SwapperBonusRateForCtTokenEnabled
   FunctionDefinition.constructor
   FunctionDefinition.setSwapperBaseRewardrate
   FunctionDefinition.setSwapperMaxProgressionFactor
   FunctionDefinition.setSwapperProgressionUpperBound
   FunctionDefinition.setSwapperBonusRewardrateForUser
   FunctionDefinition.setSwapperBonusRewardrateForCtToken
   FunctionDefinition.setSwapperBonusRewardrateForSwapToken
   FunctionDefinition.setSwapperRewards
   FunctionDefinition.enableSwapperBonusRateForUser
   FunctionDefinition.enableSwapperBonusRateForRewardToken
   FunctionDefinition.enableSwapperBonusRateForCtToken
   FunctionDefinition.getSwapperBaseRewardrate
   FunctionDefinition.getMaxProgressionFactor
   FunctionDefinition.getSwapperProgressionUpperBound
   FunctionDefinition.getSwapperBonusRewardrateForUser
   FunctionDefinition.getSwapperBonusRewardrateForCtToken
   FunctionDefinition.getSwapperBonusRewardrateForSwapToken
   FunctionDefinition.quoteSwapperRewardrate
   FunctionDefinition.swapperBonusRateForUser
   FunctionDefinition.swapperBonusRateForRewardToken
   FunctionDefinition.swapperBonusRateForCtToken

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

1: 
   Current order:
   UsingForDirective.EnumerableSet.UintSet
   VariableDeclaration._requests
   VariableDeclaration._requestsByOwner
   VariableDeclaration.lastRequestId
   VariableDeclaration.lastFinalizedRequestId
   StructDefinition.WithdrawalRequest
   StructDefinition.WithdrawalRequestStatus
   EventDefinition.WithdrawalRequested
   EventDefinition.WithdrawalClaimed
   EventDefinition.WithdrawalsFinalized
   ErrorDefinition.InvalidRequestId
   ErrorDefinition.InvalidRequestIdRange
   ErrorDefinition.RequestNotFoundOrNotFinalized
   ErrorDefinition.RequestAlreadyClaimed
   FunctionDefinition.constructor
   FunctionDefinition.getWithdrawalStatus
   FunctionDefinition.getWithdrawalRequests
   FunctionDefinition.getLastRequestId
   FunctionDefinition.getLastFinalizedRequestId
   FunctionDefinition.unfinalizedRequestNumber
   FunctionDefinition.unfinalizedAmount
   FunctionDefinition._getStatus
   FunctionDefinition.requestWithdrawal
   FunctionDefinition.prepareWithdrawal
   FunctionDefinition._finalize
   
   Suggested order:
   UsingForDirective.EnumerableSet.UintSet
   VariableDeclaration._requests
   VariableDeclaration._requestsByOwner
   VariableDeclaration.lastRequestId
   VariableDeclaration.lastFinalizedRequestId
   StructDefinition.WithdrawalRequest
   StructDefinition.WithdrawalRequestStatus
   ErrorDefinition.InvalidRequestId
   ErrorDefinition.InvalidRequestIdRange
   ErrorDefinition.RequestNotFoundOrNotFinalized
   ErrorDefinition.RequestAlreadyClaimed
   EventDefinition.WithdrawalRequested
   EventDefinition.WithdrawalClaimed
   EventDefinition.WithdrawalsFinalized
   FunctionDefinition.constructor
   FunctionDefinition.getWithdrawalStatus
   FunctionDefinition.getWithdrawalRequests
   FunctionDefinition.getLastRequestId
   FunctionDefinition.getLastFinalizedRequestId
   FunctionDefinition.unfinalizedRequestNumber
   FunctionDefinition.unfinalizedAmount
   FunctionDefinition._getStatus
   FunctionDefinition.requestWithdrawal
   FunctionDefinition.prepareWithdrawal
   FunctionDefinition._finalize

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/TokenRegistry.sol

1: 
   Current order:
   EventDefinition.TokenRegistered
   EventDefinition.TokenUnregistered
   EventDefinition.TokenRemoved
   EventDefinition.IsRewardUpdated
   EventDefinition.OracleUpdated
   UsingForDirective.EnumerableSet.AddressSet
   VariableDeclaration._treasury
   VariableDeclaration._token
   VariableDeclaration._listedTokens
   FunctionDefinition.constructor
   FunctionDefinition.registerToken
   FunctionDefinition.removeToken
   FunctionDefinition.unregisterToken
   FunctionDefinition.updateOracle
   FunctionDefinition.updateIsReward
   FunctionDefinition.getOracle
   FunctionDefinition.isRegistered
   FunctionDefinition.isRewardToken
   FunctionDefinition.getTokens
   FunctionDefinition.getSubsetOfTokens
   FunctionDefinition.getTreasury
   ModifierDefinition.onlyRegisteredToken
   
   Suggested order:
   UsingForDirective.EnumerableSet.AddressSet
   VariableDeclaration._treasury
   VariableDeclaration._token
   VariableDeclaration._listedTokens
   EventDefinition.TokenRegistered
   EventDefinition.TokenUnregistered
   EventDefinition.TokenRemoved
   EventDefinition.IsRewardUpdated
   EventDefinition.OracleUpdated
   ModifierDefinition.onlyRegisteredToken
   FunctionDefinition.constructor
   FunctionDefinition.registerToken
   FunctionDefinition.removeToken
   FunctionDefinition.unregisterToken
   FunctionDefinition.updateOracle
   FunctionDefinition.updateIsReward
   FunctionDefinition.getOracle
   FunctionDefinition.isRegistered
   FunctionDefinition.isRewardToken
   FunctionDefinition.getTokens
   FunctionDefinition.getSubsetOfTokens
   FunctionDefinition.getTreasury

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/Aave/DataTypes.sol

1: 
   Current order:
   StructDefinition.ReserveData
   StructDefinition.ReserveData2
   StructDefinition.ReserveConfigurationMap
   StructDefinition.UserConfigurationMap
   EnumDefinition.InterestRateMode
   
   Suggested order:
   EnumDefinition.InterestRateMode
   StructDefinition.ReserveData
   StructDefinition.ReserveData2
   StructDefinition.ReserveConfigurationMap
   StructDefinition.UserConfigurationMap

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/DataTypes.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

1: 
   Current order:
   EventDefinition.BorrowDebtRepayed
   EventDefinition.BorrowClaimExecuted
   EventDefinition.ClaimRouterAddressUpdated
   UsingForDirective.IERC20
   UsingForDirective.Math
   VariableDeclaration.borrowDebt
   VariableDeclaration.claimRouter
   FunctionDefinition.constructor
   ModifierDefinition.onlyClaimRouter
   FunctionDefinition.isProtectStrategy
   FunctionDefinition.highWatermark
   FunctionDefinition.getAvailableAssetsForWithdrawal
   FunctionDefinition.setClaimRouter
   FunctionDefinition._totalAssets
   FunctionDefinition.getBorrowDebt
   FunctionDefinition.updateBorrowDebt
   FunctionDefinition.executeBorrowClaim
   FunctionDefinition._requestFromVault
   FunctionDefinition._handleRewardsOnWithdraw
   FunctionDefinition._getRewardsToStrategy
   FunctionDefinition.getRewardTokenAddresses
   
   Suggested order:
   UsingForDirective.IERC20
   UsingForDirective.Math
   VariableDeclaration.borrowDebt
   VariableDeclaration.claimRouter
   EventDefinition.BorrowDebtRepayed
   EventDefinition.BorrowClaimExecuted
   EventDefinition.ClaimRouterAddressUpdated
   ModifierDefinition.onlyClaimRouter
   FunctionDefinition.constructor
   FunctionDefinition.isProtectStrategy
   FunctionDefinition.highWatermark
   FunctionDefinition.getAvailableAssetsForWithdrawal
   FunctionDefinition.setClaimRouter
   FunctionDefinition._totalAssets
   FunctionDefinition.getBorrowDebt
   FunctionDefinition.updateBorrowDebt
   FunctionDefinition.executeBorrowClaim
   FunctionDefinition._requestFromVault
   FunctionDefinition._handleRewardsOnWithdraw
   FunctionDefinition._getRewardsToStrategy
   FunctionDefinition.getRewardTokenAddresses

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/DataTypes.sol

1: 
   Current order:
   StructDefinition.ReserveData
   StructDefinition.ReserveConfigurationMap
   StructDefinition.UserConfigurationMap
   EnumDefinition.InterestRateMode
   
   Suggested order:
   EnumDefinition.InterestRateMode
   StructDefinition.ReserveData
   StructDefinition.ReserveConfigurationMap
   StructDefinition.UserConfigurationMap

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/DataTypes.sol)

```solidity
File: src/strategies/compoundV3/ICompoundV3.sol

1: 
   Current order:
   FunctionDefinition.baseTrackingBorrowSpeed
   FunctionDefinition.baseTrackingSupplySpeed
   FunctionDefinition.balanceOf
   FunctionDefinition.governor
   FunctionDefinition.isSupplyPaused
   FunctionDefinition.supply
   FunctionDefinition.isWithdrawPaused
   FunctionDefinition.withdraw
   FunctionDefinition.baseToken
   FunctionDefinition.claim
   FunctionDefinition.rewardConfig
   FunctionDefinition.admin
   FunctionDefinition.comp
   StructDefinition.Configuration
   StructDefinition.AssetConfig
   FunctionDefinition.getConfiguration
   
   Suggested order:
   StructDefinition.Configuration
   StructDefinition.AssetConfig
   FunctionDefinition.baseTrackingBorrowSpeed
   FunctionDefinition.baseTrackingSupplySpeed
   FunctionDefinition.balanceOf
   FunctionDefinition.governor
   FunctionDefinition.isSupplyPaused
   FunctionDefinition.supply
   FunctionDefinition.isWithdrawPaused
   FunctionDefinition.withdraw
   FunctionDefinition.baseToken
   FunctionDefinition.claim
   FunctionDefinition.rewardConfig
   FunctionDefinition.admin
   FunctionDefinition.comp
   FunctionDefinition.getConfiguration

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/ICompoundV3.sol)

```solidity
File: src/swapper/Swapper.sol

1: 
   Current order:
   EventDefinition.Swapped
   EventDefinition.TreasuryUpdated
   EventDefinition.RewardManagerUpdated
   UsingForDirective.Math
   UsingForDirective.IERC20
   VariableDeclaration._treasury
   VariableDeclaration._rewardManager
   VariableDeclaration._unavailableForWithdrawal
   FunctionDefinition.constructor
   FunctionDefinition.swapTokensForReward
   FunctionDefinition.setRewardManager
   FunctionDefinition.disableTokenForSwap
   FunctionDefinition.previewSwapTokensForReward
   FunctionDefinition.tokenAvailableForWithdrawal
   FunctionDefinition.amountAvailableForWithdrawal
   FunctionDefinition.getRewardManager
   FunctionDefinition.getTreasury
   FunctionDefinition._quoteSwapFromCtAssetToReward
   
   Suggested order:
   UsingForDirective.Math
   UsingForDirective.IERC20
   VariableDeclaration._treasury
   VariableDeclaration._rewardManager
   VariableDeclaration._unavailableForWithdrawal
   EventDefinition.Swapped
   EventDefinition.TreasuryUpdated
   EventDefinition.RewardManagerUpdated
   FunctionDefinition.constructor
   FunctionDefinition.swapTokensForReward
   FunctionDefinition.setRewardManager
   FunctionDefinition.disableTokenForSwap
   FunctionDefinition.previewSwapTokensForReward
   FunctionDefinition.tokenAvailableForWithdrawal
   FunctionDefinition.amountAvailableForWithdrawal
   FunctionDefinition.getRewardManager
   FunctionDefinition.getTreasury
   FunctionDefinition._quoteSwapFromCtAssetToReward

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="NC-30"></a>[NC-30] TODO Left in the code

TODOs may signal that a feature is missing or not ready for audit, consider resolving the issue and removing the TODO comment

*Instances (1)*:

```solidity
File: src/interfaces/IConcreteMultiStrategyVault.sol

29:     IStrategy strategy; //TODO: Create interface for real Strategy and implement here

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IConcreteMultiStrategyVault.sol)

### <a name="NC-31"></a>[NC-31] Use Underscores for Number Literals (add an underscore every 3 digits)

*Instances (4)*:

```solidity
File: src/registries/VaultRegistry.sol

18:     uint256 public totalVaultsAllowed = 1000;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/StrategyBase.sol

349:                 uint256 collectedFee = claimedBalance.mulDiv(rewardTokens[i].fee, 10000, Math.Rounding.Ceil);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

698:                 ) / 10000; // Normalize the fee percentage

881:         if (allotmentTotals != 10000) revert AllotmentTotalTooHigh();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-32"></a>[NC-32] Internal and private variables and functions names should begin with an underscore

According to the Solidity Style Guide, Non-`external` variable and function names should begin with an [underscore](https://docs.soliditylang.org/en/latest/style-guide.html#underscore-prefix-for-non-external-functions-and-variables)

*Instances (16)*:

```solidity
File: src/queue/WithdrawalQueue.sol

20:     uint256 private lastRequestId;

21:     uint256 private lastFinalizedRequestId;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/VaultRegistry.sol

30:     mapping(address => EnumerableSet.AddressSet) private vaultsByToken;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

25:     uint256 private borrowDebt = 0;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

10:     function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {

27:     function toShareRoundUp(

50:     function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256 result) {

67:     function toAmountRoundUp(

91:     function toValue(

104:     function sum(uint256[] memory _numbers) internal pure returns (uint256 s) {

122:     function calculateUtilization(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

68:     Strategy[] internal strategies;

71:     VaultFees private fees;

77:     address[] private rewardAddresses;

495:     function claimWithdrawal(uint256 _requestId, uint256 avaliableAssets) private returns (uint256) {

1033:     function updateUserRewardsToCurrent(address userAddress) private {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-33"></a>[NC-33] Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

*Instances (39)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

22:     event BlueprintRoleGranted(address blueprint);

23:     event VaultRegistryUpdated(address vaultRegistry);

24:     event ClaimRequested(address indexed protectionStrat, uint256 amount, address asset, address userBlueprint);

25:     event Repayment(address indexed protectionStrat, uint256 amount);

26:     event RewardAdded(address indexed protectionStrat, uint256 amount);

27:     event DustCleaned(address indexed protectionStrat, uint256 amount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/interfaces/IBeraOracle.sol

29:     event CurrencyPairsAdded(string[] currencyPairs);

32:     event CurrencyPairsRemoved(string[] currencyPairs);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IBeraOracle.sol)

```solidity
File: src/interfaces/IConcreteMultiStrategyVault.sol

42:     event ToggleVaultIdle(bool pastValue, bool newValue);

43:     event StrategyAdded(address newStrategy);

44:     event StrategyRemoved(address oldStrategy);

45:     event DepositLimitSet(uint256 limit);

46:     event StrategyAllocationsChanged(Allocation[] newAllocations);

47:     event WithdrawalQueueUpdated(address oldQueue, address newQueue);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/IConcreteMultiStrategyVault.sol)

```solidity
File: src/managers/RewardManager.sol

16:     event SwapperRewardsUpdated(

24:     event SwapperBaseRewardrateUpdated(uint16 baseRewardrate);

25:     event SwapperMaxProgressionFactorUpdated(uint16 maxProgressionFactor);

26:     event SwapperProgressionUpperBoundUpdated(uint256 progressionUpperBound);

27:     event SwapperBonusRewardrateForUserUpdated(uint16 bonusRewardrateUser);

28:     event SwapperBonusRewardrateForCtTokenUpdated(uint16 bonusRewardrateCtToken);

29:     event SwapperBonusRewardrateForSwapTokenUpdated(uint16 bonusRewardrateSwapToken);

30:     event SwapperBonusRateForRewardTokenEnabled(address rewardToken, bool enableBonusRate);

31:     event SwapperBonusRateForCtTokenEnabled(address ctAssetToken, bool enableBonusRate);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

56:     event WithdrawalClaimed(uint256 indexed requestId, address indexed recipient, uint256 amount);

60:     event WithdrawalsFinalized(uint256 indexed from, uint256 indexed to, uint256 timestamp);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

24:     event ImplementationAdded(bytes32 indexed id, ImplementationData implementation);

26:     event ImplementationRemoved(bytes32 indexed id, ImplementationData implementation);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

16:     event TokenRegistered(address indexed token, bool isReward, OracleInformation oracle);

19:     event IsRewardUpdated(address indexed token, bool isReward);

20:     event OracleUpdated(address indexed token, address oracle, uint8 decimals, string pair);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

12:     event BorrowDebtRepayed(uint256 prevAmount, uint256 substractedAmount);

13:     event BorrowClaimExecuted(uint256 amount, address recipient);

14:     event ClaimRouterAddressUpdated(address claimRouter);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

27:     event SetEnableRewards(address indexed sender, bool rewardsEnabled);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

51:     event Harvested(address indexed harvester, uint256 tvl);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/Swapper.sol

28:     event Swapped(

36:     event TreasuryUpdated(address treasury);

38:     event RewardManagerUpdated(address rewardManager);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

90:     event RequestedFunds(address indexed protectStrategy, uint256 amount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-34"></a>[NC-34] `public` functions not called by the contract should be declared `external` instead

*Instances (10)*:

```solidity
File: src/registries/TokenRegistry.sol

186:     function getTreasury() public view returns (address) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/swapper/OraclePlug.sol

102:     function getTokenRegistry() public view returns (address) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

127:     function previewSwapTokensForReward(

149:     function tokenAvailableForWithdrawal(address rewardToken_) public view returns (bool) {

169:     function getRewardManager() public view returns (address) {

175:     function getTreasury() public view returns (address) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

194:     function pause() public onlyOwner {

202:     function unpause() public onlyOwner {

507:     function getRewardTokens() public view returns (address[] memory) {

725:     function getVaultFees() public view returns (VaultFees memory) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="NC-35"></a>[NC-35] Variables need not be initialized to zero

The default value for variables is zero, so initializing them to zero is superfluous.

*Instances (22)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

73:         for (uint256 i = 0; i < len; ) {

268:         uint256 totalSent = 0;

287:             uint256 amountToBeSent = 0;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/managers/VaultManager.sol

51:         for (uint256 i = 0; i < vaultsLength; ) {

65:         for (uint256 i = 0; i < vaultsLength; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

76:         for (uint256 i = 0; i < _requestIds.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

59:         uint256 indexToBeRemoved = 0;

61:         for (uint256 i = 0; i < len; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

156:         uint256 count = 0;

157:         for (uint256 i = 0; i < tokens.length; ) {

169:         for (uint256 i = 0; i < tokens.length; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

94:         uint256 i = 0;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

25:     uint256 private borrowDebt = 0;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

326:         for (uint256 i = 0; i < rewards.length; ) {

343:         for (uint256 i = 0; i < len; ) {

346:             uint256 netReward = 0;

372:         for (uint256 i = 0; i < len; ) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

40:     uint256 public firstDeposit = 0;

454:             uint256 totalWithdrawn = 0;

583:         uint256 unfinalized = 0;

873:         uint256 allotmentTotals = 0;

1000:             for (uint256 k = 0; k < indices.length; k++) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

## Low Issues

| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | `approve()`/`safeApprove()` may revert if the current approval is not zero | 4 |
| [L-2](#L-2) | Use a 2-step ownership transfer pattern | 8 |
| [L-3](#L-3) | Some tokens may revert when zero value transfers are made | 12 |
| [L-4](#L-4) | Missing checks for `address(0)` when assigning values to address state variables | 2 |
| [L-5](#L-5) | `decimals()` is not a part of the ERC-20 standard | 3 |
| [L-6](#L-6) | `decimals()` should be of type `uint8` | 2 |
| [L-7](#L-7) | Deprecated approve() function | 2 |
| [L-8](#L-8) | Division by zero not prevented | 2 |
| [L-9](#L-9) | Duplicate import statements | 6 |
| [L-10](#L-10) | Empty Function Body - Consider commenting why | 3 |
| [L-11](#L-11) | External call recipient may consume all transaction gas | 1 |
| [L-12](#L-12) | Initializers could be front-run | 16 |
| [L-13](#L-13) | Prevent accidentally burning tokens | 10 |
| [L-14](#L-14) | Owner can renounce while system is paused | 2 |
| [L-15](#L-15) | Possible rounding issue | 2 |
| [L-16](#L-16) | Loss of precision | 2 |
| [L-17](#L-17) | Solidity version 0.8.20+ may not work on other chains due to `PUSH0` | 22 |
| [L-18](#L-18) | Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership` | 10 |
| [L-19](#L-19) | `symbol()` is not a part of the ERC-20 standard | 10 |
| [L-20](#L-20) | Unsafe ERC20 operation(s) | 4 |
| [L-21](#L-21) | Unspecific compiler version pragma | 5 |
| [L-22](#L-22) | Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions | 19 |
| [L-23](#L-23) | Upgradeable contract not initialized | 38 |
| [L-24](#L-24) | Use `initializer` for public-facing functions only. Replace with `onlyInitializing` on internal functions. | 1 |
| [L-25](#L-25) | A year is not always 365 days | 1 |

### <a name="L-1"></a>[L-1] `approve()`/`safeApprove()` may revert if the current approval is not zero

- Some tokens (like the *very popular* USDT) do not work when changing the allowance from an existing non-zero allowance value (it will revert if the current approval is not zero to protect against front-running changes of approvals). These tokens must first be approved for zero and then the actual allowance can be approved.
- Furthermore, OZ's implementation of safeApprove would throw an error if an approve is attempted from a non-zero value (`"SafeERC20: approve from non-zero to non-zero allowance"`)

Set the allowance to zero immediately before each of the existing allowance calls

*Instances (4)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

55:         baseAsset_.approve(address(lendingPool), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

98:                 if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();

206:         if (!rewardToken_.token.approve(address(this), type(uint256).max)) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

62:         IERC20(asset()).approve(address(cToken_), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

### <a name="L-2"></a>[L-2] Use a 2-step ownership transfer pattern

Recommend considering implementing a two step process where the owner or admin nominates an account and the nominated account needs to call an `acceptOwnership()` function for the transfer of ownership to fully succeed. This ensures the nominated EOA account is a valid and active account. Lack of two-step procedure for critical operations leaves them error-prone. Consider adding two step procedure on the critical functions.

*Instances (8)*:

```solidity
File: src/factories/VaultFactory.sol

14: contract VaultFactory is Ownable, Errors, IVaultFactory {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/managers/DeploymentManager.sol

16: contract DeploymentManager is Ownable, Errors, IVaultDeploymentManager {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

34: contract RewardManager is RewardManagerEvents, Ownable {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

15: contract WithdrawalQueue is Ownable, IWithdrawalQueue {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

12: contract ImplementationRegistry is Ownable, Errors, IImplementationRegistry {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

23: contract TokenRegistry is ITokenRegistry, TokenRegistryEvents, Ownable {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

13: contract VaultRegistry is IVaultRegistry, Ownable, Errors {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/swapper/Swapper.sol

45: contract Swapper is OraclePlug, Ownable, SwapperEvents, ReentrancyGuard, ISwapper {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

### <a name="L-3"></a>[L-3] Some tokens may revert when zero value transfers are made

Example: <https://github.com/d-xo/weird-erc20#revert-on-zero-value-transfers>.

In spite of the fact that EIP-20 [states](https://github.com/ethereum/EIPs/blob/46b9b698815abbfa628cd1097311deee77dd45c5/EIPS/eip-20.md?plain=1#L116) that zero-valued transfers must be accepted, some tokens, such as LEND will revert if this is attempted, which may cause transactions that involve other tokens (such as batch operations) to fully revert. Consider skipping the transfer if the amount is zero, which will also save gas.

*Instances (12)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

307:             IERC20(tokenAddress).safeTransferFrom(userBlueprint, protectionStrat, amountToBeSent);

332:             IERC20(tokenAddress).safeTransferFrom(userBlueprint, lastProtectionStrat, amount_ - totalSent);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

141:         IERC20(asset()).safeTransfer(recipient, amount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

136:         IERC20(asset()).safeTransferFrom(caller_, address(this), assets_);

169:         IERC20(asset()).safeTransfer(receiver_, assets_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/Swapper.sol

92:         IERC20(ctAssetToken_).safeTransferFrom(msg.sender, address(_treasury), ctAssetAmount_);

95:         IERC20(rewardToken_).safeTransferFrom(address(_treasury), msg.sender, rewardAmount);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

250:         IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets_);

313:         IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

451:             asset_.safeTransfer(receiver_, amount_);

479:                 asset_.safeTransfer(receiver_, amount_ - totalWithdrawn);

1044:                     IERC20(rewardAddresses[i]).safeTransfer(userAddress, rewardsToTransfer);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-4"></a>[L-4] Missing checks for `address(0)` when assigning values to address state variables

*Instances (2)*:

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

33:         claimRouter = claimRouter_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

118:         _vault = vault_;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

### <a name="L-5"></a>[L-5] `decimals()` is not a part of the ERC-20 standard

The `decimals()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (3)*:

```solidity
File: src/strategies/StrategyBase.sol

117:         _decimals = IERC20Metadata(address(baseAsset_)).decimals() + DECIMAL_OFFSET;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/OraclePlug.sol

46:         uint8 tokenDecimals = IERC20Metadata(token_).decimals();

76:         uint8 tokenDecimals = IERC20Metadata(token_).decimals();

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

### <a name="L-6"></a>[L-6] `decimals()` should be of type `uint8`

*Instances (2)*:

```solidity
File: src/strategies/Silo/EasyMathV2.sol

94:         uint256 _assetDecimals

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/swapper/OraclePlug.sol

30:     ) internal view returns (uint256 price, uint8 decimals) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

### <a name="L-7"></a>[L-7] Deprecated approve() function

Due to the inheritance of ERC20's approve function, there's a vulnerability to the ERC20 approve and double spend front running attack. Briefly, an authorized spender could spend both allowances by front running an allowance-changing transaction. Consider implementing OpenZeppelin's `.safeApprove()` function to help mitigate this.

*Instances (2)*:

```solidity
File: src/strategies/StrategyBase.sol

98:                 if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();

206:         if (!rewardToken_.token.approve(address(this), type(uint256).max)) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

### <a name="L-8"></a>[L-8] Division by zero not prevented

The divisions below take an input parameter which does not have any zero-value checks, which may lead to the functions reverting when zero is passed.

*Instances (2)*:

```solidity
File: src/strategies/Silo/EasyMathV2.sol

39:             result = numerator / totalAmount;

79:             result = numerator / totalShares;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

### <a name="L-9"></a>[L-9] Duplicate import statements

*Instances (6)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

8: import {IProtectStrategy} from "../interfaces/IProtectStrategy.sol";

11: import {IProtectStrategy} from "../interfaces/IProtectStrategy.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

5: import {ImplementationData} from "../interfaces/IImplementationRegistry.sol";

7: import {IImplementationRegistry} from "../interfaces/IImplementationRegistry.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/strategies/StrategyBase.sol

11: import {ReturnedRewards} from "../interfaces/IStrategy.sol";

12: import {IStrategy, ReturnedRewards} from "../interfaces/IStrategy.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

### <a name="L-10"></a>[L-10] Empty Function Body - Consider commenting why

*Instances (3)*:

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

154:     function _handleRewardsOnWithdraw() internal override {}

155:     function _getRewardsToStrategy(bytes memory) internal override {}

156:     function getRewardTokenAddresses() public view override returns (address[] memory _rewardTokens) {}

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

### <a name="L-11"></a>[L-11] External call recipient may consume all transaction gas

There is no limit specified on the amount of gas used, so the recipient can use up all of the transaction's gas, causing it to revert. Use `addr.call{gas: <amount>}("")` or [this](https://github.com/nomad-xyz/ExcessivelySafeCall) library instead.

*Instances (1)*:

```solidity
File: src/factories/VaultFactory.sol

42:             (bool success, ) = newVault.call(data_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

### <a name="L-12"></a>[L-12] Initializers could be front-run

Initializers could be front-run, allowing an attacker to either set their own values, take ownership of the contract, and in the best case forcing a re-deployment

*Instances (16)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

44:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

36:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

50:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

93:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

71:     function __StrategyBase_init(

80:     ) internal initializer nonReentrant {

82:         __ERC4626_init(IERC20Metadata(address(baseAsset_)));

83:         __ERC20_init(shareName_, shareSymbol_);

84:         __Ownable_init(owner_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

47:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

141:     function initialize(

150:     ) external initializer nonReentrant {

151:         __Pausable_init();

152:         __ERC4626_init(baseAsset_);

153:         __ERC20_init(shareName_, shareSymbol_);

154:         __Ownable_init(owner_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-13"></a>[L-13] Prevent accidentally burning tokens

Minting and burning tokens to address(0) prevention

*Instances (10)*:

```solidity
File: src/strategies/StrategyBase.sol

140:         _mint(receiver_, shares_);

167:         _burn(owner_, shares_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

116:             _mint(feeRecipient, feeInShare);

246:         if (feeShares > 0) _mint(feeRecipient, feeShares);

247:         _mint(receiver_, shares);

277:         return mint(shares_, msg.sender);

309:         if (feeShares > 0) _mint(feeRecipient, feeShares);

310:         _mint(receiver_, shares_);

423:         _burn(owner_, shares);

424:         if (feeShares > 0) _mint(feeRecipient, feeShares);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-14"></a>[L-14] Owner can renounce while system is paused

The contract owner or single user with a role is not prevented from renouncing the role/ownership while the contract is paused, which would cause any user assets stored in the protocol, to be locked indefinitely.

*Instances (2)*:

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

194:     function pause() public onlyOwner {

202:     function unpause() public onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-15"></a>[L-15] Possible rounding issue

Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator. Also, there is indication of multiplication and division without the use of parenthesis which could result in issues.

*Instances (2)*:

```solidity
File: src/strategies/Silo/EasyMathV2.sol

39:             result = numerator / totalAmount;

79:             result = numerator / totalShares;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

### <a name="L-16"></a>[L-16] Loss of precision

Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator

*Instances (2)*:

```solidity
File: src/strategies/Silo/EasyMathV2.sol

39:             result = numerator / totalAmount;

79:             result = numerator / totalShares;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

### <a name="L-17"></a>[L-17] Solidity version 0.8.20+ may not work on other chains due to `PUSH0`

The compiler for Solidity 0.8.20 switches the default target EVM version to [Shanghai](https://blog.soliditylang.org/2023/05/10/solidity-0.8.20-release-announcement/#important-note), which includes the new `PUSH0` op code. This op code may not yet be implemented on all L2s, so deployment on these chains will fail. To work around this issue, use an earlier [EVM](https://docs.soliditylang.org/en/v0.8.20/using-the-compiler.html?ref=zaryabs.com#setting-the-evm-version-to-target) [version](https://book.getfoundry.sh/reference/config/solidity-compiler#evm_version). While the project itself may or may not compile with 0.8.20, other projects with which it integrates, or which extend this project may, and those projects will have problems deploying these contracts/libraries.

*Instances (22)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/factories/VaultFactory.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/interfaces/Constants.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/Constants.sol)

```solidity
File: src/interfaces/DataTypes.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/interfaces/DataTypes.sol)

```solidity
File: src/managers/DeploymentManager.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/managers/VaultManager.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

4: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/Aave/DataTypes.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/DataTypes.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/DataTypes.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/DataTypes.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/swapper/Swapper.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

2: pragma solidity 0.8.24;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-18"></a>[L-18] Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership`

Use [Ownable2Step.transferOwnership](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol) which is safer. Use it as it is more secure due to 2-stage ownership transfer.

**Recommended Mitigation Steps**

Use <a href="https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol">Ownable2Step.sol</a>
  
  ```solidity
      function acceptOwnership() external {
          address sender = _msgSender();
          require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
          _transferOwnership(sender);
      }
```

*Instances (10)*:

```solidity
File: src/factories/VaultFactory.sol

5: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/managers/DeploymentManager.sol

5: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

8: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/StrategyBase.sol

9: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/Swapper.sol

12: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-19"></a>[L-19] `symbol()` is not a part of the ERC-20 standard

The `symbol()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (10)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

46:             string.concat("Concrete Earn AaveV3 ", metaERC20.symbol(), " Strategy"),

47:             string.concat("ctAv3-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

38:             string.concat("Concrete Earn Protect ", metaERC20.symbol(), " Strategy"),

39:             string.concat("ctPct-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

52:             string.concat("Concrete Earn RadiantV2 ", metaERC20.symbol(), " Strategy"),

53:             string.concat("ctRdV2-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

95:             string.concat("Concrete Earn SiloV1 ", baseAsset_.symbol(), " Strategy"),

96:             string.concat("ctSlV1-", baseAsset_.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

49:             string.concat("Concrete Earn CompoundV3 ", metaERC20.symbol(), " Strategy"),

50:             string.concat("ctCM3-", metaERC20.symbol()),

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

### <a name="L-20"></a>[L-20] Unsafe ERC20 operation(s)

*Instances (4)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

55:         baseAsset_.approve(address(lendingPool), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

98:                 if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();

206:         if (!rewardToken_.token.approve(address(this), type(uint256).max)) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

62:         IERC20(asset()).approve(address(cToken_), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

### <a name="L-21"></a>[L-21] Unspecific compiler version pragma

*Instances (5)*:

```solidity
File: src/strategies/Aave/DataTypes.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/DataTypes.sol)

```solidity
File: src/strategies/Radiant/DataTypes.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/DataTypes.sol)

```solidity
File: src/strategies/Silo/EasyMathV2.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/EasyMathV2.sol)

```solidity
File: src/strategies/Silo/IBaseSiloV1.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/IBaseSiloV1.sol)

```solidity
File: src/strategies/Silo/ISiloV1.sol

2: pragma solidity >=0.8.20;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/ISiloV1.sol)

### <a name="L-22"></a>[L-22] Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions

See [this](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps) link for a description of this storage variable. While some contracts may not currently be sub-classed, adding the variable now protects against forgetting to add it in the future.

*Instances (19)*:

```solidity
File: src/strategies/Aave/IAaveV3.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/IAaveV3.sol)

```solidity
File: src/strategies/Radiant/IRadiantV2.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/IRadiantV2.sol)

```solidity
File: src/strategies/Silo/IBaseSiloV1.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/IBaseSiloV1.sol)

```solidity
File: src/strategies/StrategyBase.sol

4: import {ERC4626Upgradeable, IERC20, IERC20Metadata, IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

8: import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

9: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

25:     ERC4626Upgradeable,

27:     OwnableUpgradeable,

29:     PausableUpgradeable

133:     ) internal virtual override(ERC4626Upgradeable) whenNotPaused onlyVault {

161:     ) internal virtual override(ERC4626Upgradeable) whenNotPaused onlyVault {

178:     function totalAssets() public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/swapper/OraclePlug.sol

6: import {IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

4: import {ERC4626Upgradeable, IERC20, IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

8: import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

28:     ERC4626Upgradeable,

31:     PausableUpgradeable,

32:     OwnableUpgradeable,

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-23"></a>[L-23] Upgradeable contract not initialized

Upgradeable contracts are initialized via an initializer function rather than by a constructor. Leaving such a contract uninitialized may lead to it being taken over by a malicious user

*Instances (38)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

44:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/Aave/IAaveV3.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/IAaveV3.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

36:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/IRadiantV2.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/IRadiantV2.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

50:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/IBaseSiloV1.sol

4: import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/IBaseSiloV1.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

93:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

4: import {ERC4626Upgradeable, IERC20, IERC20Metadata, IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

8: import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

9: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

25:     ERC4626Upgradeable,

27:     OwnableUpgradeable,

29:     PausableUpgradeable

71:     function __StrategyBase_init(

80:     ) internal initializer nonReentrant {

82:         __ERC4626_init(IERC20Metadata(address(baseAsset_)));

83:         __ERC20_init(shareName_, shareSymbol_);

84:         __Ownable_init(owner_);

133:     ) internal virtual override(ERC4626Upgradeable) whenNotPaused onlyVault {

161:     ) internal virtual override(ERC4626Upgradeable) whenNotPaused onlyVault {

178:     function totalAssets() public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

47:         __StrategyBase_init(

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/OraclePlug.sol

6: import {IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/OraclePlug.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

4: import {ERC4626Upgradeable, IERC20, IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

8: import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

28:     ERC4626Upgradeable,

31:     PausableUpgradeable,

32:     OwnableUpgradeable,

88:     event Initialized(address indexed vaultName, address indexed underlyingAsset);

123:         _disableInitializers();

141:     function initialize(

150:     ) external initializer nonReentrant {

151:         __Pausable_init();

152:         __ERC4626_init(baseAsset_);

153:         __ERC20_init(shareName_, shareSymbol_);

154:         __Ownable_init(owner_);

178:         emit Initialized(address(this), address(baseAsset_));

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="L-24"></a>[L-24] Use `initializer` for public-facing functions only. Replace with `onlyInitializing` on internal functions

See [What's the difference between onlyInitializing and initializer](https://forum.openzeppelin.com/t/whats-the-difference-between-onlyinitializing-and-initialzer/25789) and <https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-onlyInitializing-->

*Instances (1)*:

```solidity
File: src/strategies/StrategyBase.sol

80:     ) internal initializer nonReentrant {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

### <a name="L-25"></a>[L-25] A year is not always 365 days

On leap years, the number of days is 366, so calculations during those years will return the wrong value

*Instances (1)*:

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

44:     uint256 private constant SECONDS_PER_YEAR = 365.25 days;

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

## Medium Issues

| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Contracts are vulnerable to fee-on-transfer accounting-related issues | 3 |
| [M-2](#M-2) | Centralization Risk for trusted owners | 108 |
| [M-3](#M-3) | `increaseAllowance/decreaseAllowance` won't work on mainnet for USDT | 2 |
| [M-4](#M-4) | Unsafe use of `transfer()`/`transferFrom()`/`approve()`/ with `IERC20` | 2 |

### <a name="M-1"></a>[M-1] Contracts are vulnerable to fee-on-transfer accounting-related issues

Consistently check account balance before and after transfers for Fee-On-Transfer discrepancies. As arbitrary ERC20 tokens can be used, the amount here should be calculated every time to take into consideration a possible fee-on-transfer or deflation.
Also, it's a good practice for the future of the solution.

Use the balance before and after the transfer to calculate the received amount instead of assuming that it would be equal to the amount passed as a parameter. Or explicitly document that such tokens shouldn't be used and won't be supported

*Instances (3)*:

```solidity
File: src/strategies/StrategyBase.sol

136:         IERC20(asset()).safeTransferFrom(caller_, address(this), assets_);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

250:         IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets_);

313:         IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="M-2"></a>[M-2] Centralization Risk for trusted owners

#### Impact

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (108)*:

```solidity
File: src/claimRouter/ClaimRouter.sol

35: contract ClaimRouter is AccessControl, Errors, IClaimRouter, OraclePlug, ClaimRouterEvents {

86:     function setVaultRegistry(address vaultRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {

95:     function setTokenCascade(address[] memory tokenCascade_) external onlyRole(DEFAULT_ADMIN_ROLE) {

191:     ) external onlyRole(BLUEPRINT_ROLE) {

237:     ) external onlyRole(BLUEPRINT_ROLE) {

246:     function repay(address tokenAddress, uint256 amount_, address userBlueprint) external onlyRole(BLUEPRINT_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/claimRouter/ClaimRouter.sol)

```solidity
File: src/factories/VaultFactory.sol

14: contract VaultFactory is Ownable, Errors, IVaultFactory {

21:     constructor(address owner) Ownable(owner) {}

32:     ) external onlyOwner returns (address newVault) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/factories/VaultFactory.sol)

```solidity
File: src/managers/DeploymentManager.sol

16: contract DeploymentManager is Ownable, Errors, IVaultDeploymentManager {

32:     ) Ownable(owner_) {

42:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

49:     function removeImplementation(bytes32 id_) external onlyOwner {

58:     function deployNewVault(bytes32 id_, bytes calldata data_) external onlyOwner returns (address newVaultAddress) {

75:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

83:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {

89:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/DeploymentManager.sol)

```solidity
File: src/managers/RewardManager.sol

34: contract RewardManager is RewardManagerEvents, Ownable {

59:     ) Ownable(owner_) {

79:     function setSwapperBaseRewardrate(uint16 baseRewardrate_) external onlyOwner {

88:     function setSwapperMaxProgressionFactor(uint16 maxProgressionFactor_) external onlyOwner {

97:     function setSwapperProgressionUpperBound(uint256 progressionUpperBound_) external onlyOwner {

105:     function setSwapperBonusRewardrateForUser(uint16 bonusRewardrateForUser_) external onlyOwner {

114:     function setSwapperBonusRewardrateForCtToken(uint16 bonusRewardrateForCtToken_) external onlyOwner {

123:     function setSwapperBonusRewardrateForSwapToken(uint16 bonusRewardrateForSwapToken_) external onlyOwner {

144:     ) external onlyOwner {

173:     function enableSwapperBonusRateForUser(address user_, bool enableBonusRate_) external onlyOwner {

182:     function enableSwapperBonusRateForRewardToken(address rewardToken_, bool enableBonusRate_) external onlyOwner {

191:     function enableSwapperBonusRateForCtToken(address ctAssetToken_, bool enableBonusRate_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/RewardManager.sol)

```solidity
File: src/managers/VaultManager.sol

12: contract VaultManager is AccessControl {

29:     ) external onlyRole(DEFAULT_ADMIN_ROLE) {

39:     function pauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

43:     function unpauseVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

47:     function pauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

61:     function unpauseAllVaults() external onlyRole(VAULT_MANAGER_ROLE) {

78:     ) external onlyRole(VAULT_MANAGER_ROLE) returns (address newVaultAddress) {

87:     ) external onlyRole(VAULT_MANAGER_ROLE) {

91:     function removeImplementation(bytes32 id_) external onlyRole(VAULT_MANAGER_ROLE) {

95:     function removeVault(address vault_, bytes32 vaultId_) external onlyRole(VAULT_MANAGER_ROLE) {

99:     function setVaultFees(address vault_, VaultFees calldata fees_) external onlyRole(VAULT_MANAGER_ROLE) {

103:     function setFeeRecipient(address vault_, address newRecipient_) external onlyRole(VAULT_MANAGER_ROLE) {

107:     function toggleIdleVault(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

116:     ) external onlyRole(VAULT_MANAGER_ROLE) {

120:     function removeStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

129:     ) external onlyRole(VAULT_MANAGER_ROLE) {

133:     function pushFundsToStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

137:     function pushFundsToSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

145:     ) external onlyRole(VAULT_MANAGER_ROLE) {

149:     function pullFundsFromSingleStrategy(address vault_, uint256 index_) external onlyRole(VAULT_MANAGER_ROLE) {

153:     function pullFundsFromStrategies(address vault_) external onlyRole(VAULT_MANAGER_ROLE) {

157:     function setDepositLimit(address vault_, uint256 limit_) external onlyRole(VAULT_MANAGER_ROLE) {

161:     function batchClaimWithdrawal(address vault_, uint256 maxRequests) external onlyRole(VAULT_MANAGER_ROLE) {

165:     function setWithdrawalQueue(address vault_, address withdrawalQueue_) external onlyRole(VAULT_MANAGER_ROLE) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/managers/VaultManager.sol)

```solidity
File: src/queue/WithdrawalQueue.sol

15: contract WithdrawalQueue is Ownable, IWithdrawalQueue {

67:     constructor(address vault) Ownable(vault) {

109:     function unfinalizedAmount() external view virtual onlyOwner returns (uint256) {

131:     function requestWithdrawal(address recipient, uint256 amount) external virtual onlyOwner {

156:     ) external onlyOwner returns (address recipient, uint256 amount, uint256 avaliableAssets) {

185:     function _finalize(uint256 _lastRequestIdToBeFinalized) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/queue/WithdrawalQueue.sol)

```solidity
File: src/registries/ImplementationRegistry.sol

12: contract ImplementationRegistry is Ownable, Errors, IImplementationRegistry {

29:     constructor(address owner_) Ownable(owner_) {}

35:     function addImplementation(bytes32 id_, ImplementationData memory implementation_) external onlyOwner {

50:     function removeImplementation(bytes32 id_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/ImplementationRegistry.sol)

```solidity
File: src/registries/TokenRegistry.sol

23: contract TokenRegistry is ITokenRegistry, TokenRegistryEvents, Ownable {

31:     constructor(address owner_, address treasury_) Ownable(owner_) {

51:     ) external override(ITokenRegistry) onlyOwner {

72:     ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {

83:     ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {

98:     ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {

111:     function updateIsReward(address tokenAddress_, bool isReward_) external override(ITokenRegistry) onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/TokenRegistry.sol)

```solidity
File: src/registries/VaultRegistry.sol

13: contract VaultRegistry is IVaultRegistry, Ownable, Errors {

39:     constructor(address owner_) Ownable(owner_) {}

46:     function addVault(address vault_, bytes32 vaultId_) external override onlyOwner {

68:     function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {

116:     function setVaultByTokenLimit(uint256 vaultByTokenLimit_) external onlyOwner {

122:     function setTotalVaultsAllowed(uint256 totalVaultsAllowed_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/registries/VaultRegistry.sol)

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

111:     function retireStrategy() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/ProtectStrategy/ProtectStrategy.sol

89:     function setClaimRouter(address claimRouter_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/ProtectStrategy/ProtectStrategy.sol)

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

121:     function retireStrategy() external onlyOwner {

144:     function setEnableRewards(bool _rewardsEnabled) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

168:     function retireStrategy() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

```solidity
File: src/strategies/StrategyBase.sol

191:     function addRewardToken(RewardToken calldata rewardToken_) external onlyOwner nonReentrant {

217:     function removeRewardToken(RewardToken calldata rewardToken_) external onlyOwner {

236:     function modifyRewardFeeForRewardToken(uint256 newFee_, RewardToken calldata rewardToken_) external onlyOwner {

261:     function setFeeRecipient(address feeRecipient_) external onlyOwner {

273:     function setDepositLimit(uint256 depositLimit_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

114:     function retireStrategy() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

```solidity
File: src/swapper/Swapper.sol

45: contract Swapper is OraclePlug, Ownable, SwapperEvents, ReentrancyGuard, ISwapper {

65:     ) Ownable(owner_) OraclePlug(tokenRegistry_) {

105:     function setRewardManager(address rewardManager_) external onlyOwner {

113:     function disableTokenForSwap(address token_, bool disableSwap_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/swapper/Swapper.sol)

```solidity
File: src/vault/ConcreteMultiStrategyVault.sol

194:     function pause() public onlyOwner {

202:     function unpause() public onlyOwner {

744:     function setVaultFees(VaultFees calldata newFees_) external takeFees onlyOwner {

754:     function setFeeRecipient(address newRecipient_) external onlyOwner {

769:     function setWithdrawalQueue(address withdrawalQueue_) external onlyOwner {

795:     function toggleVaultIdle() external onlyOwner {

814:     ) external nonReentrant onlyOwner takeFees {

837:     function removeStrategy(uint256 index_) external nonReentrant onlyOwner takeFees {

868:     ) external nonReentrant onlyOwner takeFees {

895:     function pushFundsToStrategies() public onlyOwner {

910:     function pullFundsFromStrategies() public onlyOwner {

930:     function pullFundsFromSingleStrategy(uint256 index_) public onlyOwner {

945:     function pushFundsIntoSingleStrategy(uint256 index_) external onlyOwner {

965:     function pushFundsIntoSingleStrategy(uint256 index_, uint256 amount) external onlyOwner {

978:     function setDepositLimit(uint256 newLimit_) external onlyOwner {

989:     function harvestRewards(bytes memory encodedData) external onlyOwner nonReentrant {

1059:     function batchClaimWithdrawal(uint256 maxRequests) external onlyOwner nonReentrant {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)

### <a name="M-3"></a>[M-3] `increaseAllowance/decreaseAllowance` won't work on mainnet for USDT

On mainnet, the mitigation to be compatible with `increaseAllowance/decreaseAllowance` isn't applied: <https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7#code>, meaning it reverts on setting a non-zero & non-max allowance, unless the allowance is already zero.

*Instances (2)*:

```solidity
File: src/strategies/Radiant/RadiantV2Strategy.sol

62:         baseAsset_.safeIncreaseAllowance(address(lendingPool), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Radiant/RadiantV2Strategy.sol)

```solidity
File: src/strategies/Silo/SiloV1Strategy.sol

105:         IERC20(baseAsset_).safeIncreaseAllowance(address(silo), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Silo/SiloV1Strategy.sol)

### <a name="M-4"></a>[M-4] Unsafe use of `transfer()`/`transferFrom()`/`approve()`/ with `IERC20`

Some tokens do not implement the ERC20 standard properly but are still accepted by most code that accepts ERC20 tokens.  For example Tether (USDT)'s `transfer()` and `transferFrom()` functions on L1 do not return booleans as the specification requires, and instead have no return value. When these sorts of tokens are cast to `IERC20`, their [function signatures](https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca) do not match and therefore the calls made, revert (see [this](https://gist.github.com/IllIllI000/2b00a32e8f0559e8f386ea4f1800abc5) link for a test case). Use OpenZeppelin's `SafeERC20`'s `safeTransfer()`/`safeTransferFrom()` instead

*Instances (2)*:

```solidity
File: src/strategies/Aave/AaveV3Strategy.sol

55:         baseAsset_.approve(address(lendingPool), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/Aave/AaveV3Strategy.sol)

```solidity
File: src/strategies/compoundV3/CompoundV3Strategy.sol

62:         IERC20(asset()).approve(address(cToken_), type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/compoundV3/CompoundV3Strategy.sol)

## High Issues

| |Issue|Instances|
|-|:-|:-:|
| [H-1](#H-1) | IERC20.approve() will revert for USDT | 2 |

### <a name="H-1"></a>[H-1] IERC20.approve() will revert for USDT

Use forceApprove() from SafeERC20

*Instances (2)*:

```solidity
File: src/strategies/StrategyBase.sol

98:                 if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();

206:         if (!rewardToken_.token.approve(address(this), type(uint256).max)) {

```

[Link to code](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)
