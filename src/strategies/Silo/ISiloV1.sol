// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.20;

import "./IBaseSiloV1.sol";

interface ISiloRepository {
    function getSilo(address _asset) external view returns (address);
}

interface ISiloIncentivesController {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
    function claimRewardsToSelf(address[] calldata assets, uint256 amount) external returns (uint256);
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);
    function getUserUnclaimedRewards(address user) external view returns (uint256);
    //slither-disable-next-line naming-convention
    function REWARD_TOKEN() external view returns (address);
}

interface ISilo is IBaseSilo {
    function deposit(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 collateralAmount, uint256 collateralShare);
    function withdraw(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);
}
