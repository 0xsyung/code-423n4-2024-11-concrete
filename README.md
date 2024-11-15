# Concrete audit details

- Total Prize Pool: $112,250 in USDC
  - HM awards: $72,480 in USDC
  - QA awards: $3,020 in USDC
  - Judge awards: $8,500 in USDC
  - Validator awards: $5,500 USDC
  - Scout awards: $500 in USDC
  - Mitigation Review: $22,250 in USDC - details to be confirmed
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts November 15, 2024 20:00 UTC
- Ends November 29, 2024 20:00 UTC

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-11-concrete/blob/main/4naly3er-report.md).

Slither's output can be found [here](https://github.com/code-423n4/2024-11-concrete/blob/main/slither.txt).

_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

# Overview

Concrete is a blockchain protocol that allows DeFi users to optimize on capital efficiency by protecting leveraged positions against collateral depreciation and by offering attractive yield opportunities for liquidity providers.

## Links

- **Previous audits:** [Earn V1_SSC.pdf](https://github.com/code-423n4/2024-11-concrete/blob/main/Earn%20V1%20_%20SSC.pdf)
- **Documentation:** <https://blueprint-finance.gitbook.io/concrete_protocol/pSPVTC2wbOO8D1NFQXyP/>
- **Website:** <https://blueprintfinance.com/>
- **X/Twitter:** <https://x.com/Blueprint_DeFi>

---


# Scope

*See [scope.txt](https://github.com/code-423n4/2024-11-concrete/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/claimRouter/ClaimRouter.sol | 2| **** | 237 | |@openzeppelin/contracts/access/AccessControl.sol<br>@openzeppelin/contracts/utils/math/Math.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/interfaces/IERC20.sol|
| /src/factories/VaultFactory.sol | 1| **** | 21 | |@openzeppelin/contracts/proxy/Clones.sol<br>@openzeppelin/contracts/access/Ownable.sol|
| /src/interfaces/Constants.sol | ****| **** | 3 | ||
| /src/interfaces/DataTypes.sol | ****| **** | 23 | ||
| /src/interfaces/Errors.sol | ****| 1 | 67 | |@openzeppelin/contracts/interfaces/IERC4626.sol|
| /src/interfaces/IBeraOracle.sol | ****| 1 | 3 | ||
| /src/interfaces/IClaimRouter.sol | ****| 1 | 10 | ||
| /src/interfaces/IConcreteMultiStrategyVault.sol | ****| 1 | 36 | ||
| /src/interfaces/IImplementationRegistry.sol | ****| 1 | 7 | ||
| /src/interfaces/IMockProtectStrategy.sol | ****| 1 | 4 | ||
| /src/interfaces/IMockStrategy.sol | ****| 1 | 4 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol|
| /src/interfaces/IProtectStrategy.sol | ****| 1 | 4 | ||
| /src/interfaces/IRewardManager.sol | ****| 1 | 3 | ||
| /src/interfaces/IStrategy.sol | ****| 1 | 8 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol|
| /src/interfaces/ISwapper.sol | ****| 1 | 3 | ||
| /src/interfaces/ITokenRegistry.sol | ****| 1 | 4 | ||
| /src/interfaces/IVaultDeploymentManager.sol | ****| 1 | 4 | ||
| /src/interfaces/IVaultFactory.sol | ****| 1 | 4 | ||
| /src/interfaces/IVaultRegistry.sol | ****| 1 | 3 | ||
| /src/interfaces/IWithdrawalQueue.sol | ****| 1 | 3 | ||
| /src/managers/DeploymentManager.sol | 1| **** | 50 | |@openzeppelin/contracts/access/Ownable.sol|
| /src/managers/RewardManager.sol | 2| **** | 172 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| /src/managers/VaultManager.sol | 1| **** | 106 | |@openzeppelin/contracts/access/AccessControl.sol|
| /src/queue/WithdrawalQueue.sol | 1| **** | 117 | |@openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol<br>@openzeppelin/contracts/access/Ownable.sol|
| /src/registries/ImplementationRegistry.sol | 1| **** | 50 | |@openzeppelin/contracts/access/Ownable.sol|
| /src/registries/TokenRegistry.sol | 2| **** | 106 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/utils/structs/EnumerableSet.sol|
| /src/registries/VaultRegistry.sol | 1| **** | 74 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol|
| /src/strategies/Aave/AaveV3Strategy.sol | 1| **** | 73 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| /src/strategies/Aave/DataTypes.sol | 1| **** | 45 | ||
| /src/strategies/Aave/IAaveV3.sol | ****| 7 | 11 | |@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol|
| /src/strategies/ProtectStrategy/ProtectStrategy.sol | 2| **** | 82 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| /src/strategies/Radiant/DataTypes.sol | 1| **** | 28 | ||
| /src/strategies/Radiant/IRadiantV2.sol | ****| 5 | 9 | |@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol|
| /src/strategies/Radiant/RadiantV2Strategy.sol | 1| **** | 89 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| /src/strategies/Silo/EasyMathV2.sol | 1| **** | 79 | ||
| /src/strategies/Silo/IBaseSiloV1.sol | ****| 1 | 12 | |@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol|
| /src/strategies/Silo/ISiloV1.sol | ****| 3 | 6 | ||
| /src/strategies/Silo/SiloV1Strategy.sol | 1| **** | 130 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| /src/strategies/StrategyBase.sol | 1| **** | 187 | |@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/math/Math.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol<br>@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol<br>@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol<br>@blueprint-finance/hub-and-spokes-libraries/src/libraries/TokenHelper.sol|
| /src/strategies/compoundV3/CompoundV3Strategy.sol | 1| **** | 73 | |@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| /src/strategies/compoundV3/ICompoundV3.sol | ****| 5 | 44 | ||
| /src/swapper/OraclePlug.sol | 1| **** | 60 | |@openzeppelin/contracts/utils/math/Math.sol<br>@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol<br>@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/swapper/Swapper.sol | 2| **** | 92 | |@openzeppelin/contracts/utils/math/Math.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol<br>@openzeppelin/contracts/access/Ownable.sol|
| /src/vault/ConcreteMultiStrategyVault.sol | 1| **** | 568 | |@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol<br>@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol<br>@openzeppelin/contracts/utils/math/Math.sol|
| **Totals** | **26** | **37** | **2714** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2024-11-concrete/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./script/Chains.sol |
| ./script/DeployConfig.s.sol |
| ./script/DeployEarn.s.sol |
| ./script/DeployNewVault.s.sol |
| ./script/Deployer.sol |
| ./script/strategies/DeployAaveStratAndAssign.s.sol |
| ./script/strategies/DeployBaseStratAndAssign.s.sol |
| ./script/strategies/DeployCompoundStratAndAssign.s.sol |
| ./script/strategies/DeployProtectStratAndAssign.s.sol |
| ./script/strategies/DeployRadiantStratAndAssign.s.sol |
| ./script/strategies/DeploySiloStratAndAssign.s.sol |
| ./test/ClaimRouter.t.sol |
| ./test/ConcreteMultiStrategyVault.t.sol |
| ./test/DeploymentAndRegistry.t.sol |
| ./test/RewardManager.t.sol |
| ./test/StrategyBase.t.sol |
| ./test/Swapper.t.sol |
| ./test/TokenRegistry.t.sol |
| ./test/VaultManager.t.sol |
| ./test/strategies/AaveV3Strategy.t.sol |
| ./test/strategies/CompoundV3Strategy.t.sol |
| ./test/strategies/ProtectStrategy.t.sol |
| ./test/strategies/RadiantV2Starategy.t.sol |
| ./test/strategies/SiloV1Strategy.t.sol |
| ./test/utils/examples/ExampleStrategyBaseImplementation.sol |
| ./test/utils/mocks/MockBeraOracle.sol |
| ./test/utils/mocks/MockERC20.sol |
| ./test/utils/mocks/MockERC4626.sol |
| ./test/utils/mocks/MockERC4626Protect.sol |
| ./test/utils/mocks/MockERC4626Queue.sol |
| Totals: 30 |

## Scoping Q &amp; A

### General questions

### Are there any ERC20's in scope?: Yes

| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| ERC20 used by the protocol              |      Any (all possible ERC20s)         |
| Test coverage                           | 77.45%                        |
| ERC721 used  by the protocol            |        N/A          |
| ERC777 used by the protocol             |        N/A           |
| ERC1155 used by the protocol            |        N/A          |
| Chains the protocol will be deployed on | Ethereum,BSC,Other,ArbitrumCorn
Berachain
  |

### ERC20 token behaviors in scope

| Question                                                                                                                                                   | Answer |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| [Missing return values](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#missing-return-values)                                                      |   Out of scope  |
| [Fee on transfer](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#fee-on-transfer)                                                                  |  In scope  |
| [Balance changes outside of transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops) | In scope    |
| [Upgradeability](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#upgradable-tokens)                                                                 |   In scope  |
| [Flash minting](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#flash-mintable-tokens)                                                              | Out of scope    |
| [Pausability](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens)                                                                      | In scope    |
| [Approval race protections](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#approval-race-protections)                                              | In scope    |
| [Revert on approval to zero address](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-approval-to-zero-address)                            | In scope    |
| [Revert on zero value approvals](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-approvals)                                    | In scope    |
| [Revert on zero value transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-transfers)                                    | In scope    |
| [Revert on transfer to the zero address](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-transfer-to-the-zero-address)                    | In scope    |
| [Revert on large approvals and/or transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-large-approvals--transfers)                  | In scope    |
| [Doesn't revert on failure](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#no-revert-on-failure)                                                   |  In scope   |
| [Multiple token addresses](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-transfers)                                          | In scope    |
| [Low decimals ( < 6)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#low-decimals)                                                                 |   In scope  |
| [High decimals ( > 18)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#high-decimals)                                                              | In scope    |
| [Blocklists](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#tokens-with-blocklists)                                                                | In scope    |

### External integrations (e.g., Uniswap) behavior in scope

| Question                                                  | Answer |
| --------------------------------------------------------- | ------ |
| Enabling/disabling fees (e.g. Blur disables/enables fees) | Yes   |
| Pausability (e.g. Uniswap pool gets paused)               |  Yes   |
| Upgradeability (e.g. Uniswap gets upgraded)               |   Yes  |

### EIP compliance checklist

| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| [ConcreteMultiStrategyVault.sol](https://github.com/code-423n4/2024-11-concrete/blob/main/src/vault/ConcreteMultiStrategyVault.sol)                         | ERC4626             |
| [StrategyBase.sol](https://github.com/code-423n4/2024-11-concrete/blob/main/src/strategies/StrategyBase.sol)                       | ERC4626                 |

# Additional context

## Main invariants

The only shareholder of strategies are multi-strategy vaults.

## Attack ideas (where to focus for bugs)

- Funds locked
- DoS
- Exploitation of roles
- dust in vaults (possible reverts related to that)
- inadvertent reverts in general

## All trusted roles in the protocol

| Role                                |
| --------------------------------------- |
| Owner     (multisig)                     |  

## Describe any novel or unique curve logic or mathematical models implemented in the contracts

N/A

## Running tests

```bash
git clone --recurse https://github.com/code-423n4/2024-11-concrete.git
cd 2024-11-concrete
export NPM_TOKEN=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
# make sure that `//registry.npmjs.org/:_authToken=${NPM_TOKEN}` is added in the ./.npmrc file
yarn
forge install
forge build
forge test
forge coverage
```

![](https://github.com/user-attachments/assets/378203c8-6300-49e0-ad6d-3129d465ef2f)

## Miscellaneous

Employees of Concrete and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.
