//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

struct ReturnedRewards {
    address rewardAddress;
    uint256 rewardAmount;
}

interface IStrategy is IERC4626 {
    function getAvailableAssetsForWithdrawal() external view returns (uint256);

    function isProtectStrategy() external returns (bool);

    function harvestRewards(bytes memory) external returns (ReturnedRewards[] memory);
}
