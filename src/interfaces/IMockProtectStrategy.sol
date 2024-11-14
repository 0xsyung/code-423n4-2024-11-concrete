//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IMockStrategy} from "./IMockStrategy.sol";

interface IMockProtectStrategy is IMockStrategy {
    function getAvailableAssetsForWithdrawal() external view returns (uint256);

    function setAvailableAssetsZero(bool _avaliableAssetsZero) external;

    function executeBorrowClaim(uint256 amount, address recipient) external;

    function getBorrowDebt() external view returns (uint256);

    function updateBorrowDebt(uint256 amount) external;
}
