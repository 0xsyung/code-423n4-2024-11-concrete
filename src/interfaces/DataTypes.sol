// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

enum TokenFilterTypes {
    isRegistered,
    isReward
}

struct OracleInformation {
    address addr;
    uint8 decimals;
    string pair; // e.g. "ETH/USDC"
}

struct TokenInformation {
    bool isRegistered;
    bool isReward;
    OracleInformation oracle;
}

struct SwapperRewards {
    uint16 baseRewardrate;
    uint16 maxProgressionFactor;
    uint176 progressionUpperBound;
    uint16 bonusRewardrateUser;
    uint16 bonusRewardrateCtToken;
    uint16 bonusRewardrateSwapToken;
}
