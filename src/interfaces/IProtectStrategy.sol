//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IStrategy} from "./IStrategy.sol";

interface IProtectStrategy is IStrategy {
    function executeBorrowClaim(uint256 amount, address recipient) external;

    function getBorrowDebt() external view returns (uint256);

    function updateBorrowDebt(uint256 amount) external;
    function highWatermark() external view returns (uint256);
    function setClaimRouter(address claimRouter_) external;
    function claimRouter() external view returns (address);
}
