

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

