//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface IMockStrategy is IERC4626 {
    function getAvailableAssetsForWithdrawal() external view returns (uint256);

    function setAvailableAssetsZero(bool _avaliableAssetsZero) external;

    function isProtectStrategy() external returns (bool);

    function setHighWatermark(uint256 _highWatermark) external;

    function highWatermark() external view returns (uint256);
}
