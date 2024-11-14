//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IStrategy} from "./IStrategy.sol";

// Example performanceFee: [{0000, 500, 300}, {501, 2000, 1000}, {2001, 5000, 2000}, {5001, 10000, 5000}]
// == 0-5% increase 3%, 5.01-20% increase 10%, 20.01-50% increase 20%, 50.01-100% increase 50%
struct GraduatedFee {
    uint256 lowerBound;
    uint256 upperBound;
    uint64 fee;
}

///@notice VaultFees are represented in BPS
///@dev all downstream math needs to be / 10_000 because 10_000 bps == 100%
struct VaultFees {
    uint64 depositFee;
    uint64 withdrawalFee;
    uint64 protocolFee;
    GraduatedFee[] performanceFee;
}

struct Allocation {
    uint256 index;
    uint256 amount; // Represented in BPS of the amount of ETF that should go into strategy
}

struct Strategy {
    IStrategy strategy; //TODO: Create interface for real Strategy and implement here
    Allocation allocation;
}

struct VaultInitParams {
    address feeRecipient;
    VaultFees fees;
    uint256 depositLimit;
    address owner;
}

interface IConcreteMultiStrategyVault {
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ToggleVaultIdle(bool pastValue, bool newValue);
    event StrategyAdded(address newStrategy);
    event StrategyRemoved(address oldStrategy);
    event DepositLimitSet(uint256 limit);
    event StrategyAllocationsChanged(Allocation[] newAllocations);
    event WithdrawalQueueUpdated(address oldQueue, address newQueue);

    function pause() external;
    function unpause() external;
    function setVaultFees(VaultFees calldata newFees_) external;
    function setFeeRecipient(address newRecipient_) external;
    function toggleVaultIdle() external;
    function addStrategy(uint256 index_, bool replace_, Strategy calldata newStrategy_) external;
    function removeStrategy(uint256 index_) external;
    function changeAllocations(Allocation[] calldata allocations_, bool redistribute_) external;
    function setDepositLimit(uint256 limit_) external;
    function pushFundsToStrategies() external;
    function pushFundsIntoSingleStrategy(uint256 index_, uint256 amount) external;
    function pushFundsIntoSingleStrategy(uint256 index_) external;
    function pullFundsFromStrategies() external;
    function pullFundsFromSingleStrategy(uint256 index_) external;
    function protectStrategy() external view returns (address);
    function getAvailableAssetsForWithdrawal() external view returns (uint256);
    function requestFunds(uint256 amount_) external;
    function setWithdrawalQueue(address withdrawalQueue_) external;
    function batchClaimWithdrawal(uint256 maxRequests) external;
}
