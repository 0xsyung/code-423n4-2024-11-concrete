//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

enum VaultFlags {
    BUFFER,
    SPLITTER,
    MONEYMARKET,
    DEBT,
    COLLATERAL
}

interface IClaimRouter {
    function requestToken(
        VaultFlags flags,
        address tokenAddress,
        uint256 amount,
        address payable userBlueprint
    ) external;
    function addRewards(address tokenAddress, uint256 amount, address userBlueprint) external;
    function repay(address tokenAddress, uint256 amount, address userBlueprint) external;
}
