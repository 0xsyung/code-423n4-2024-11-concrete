//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

interface ISwapper {
    function swapTokensForReward(address ctAssetToken_, address rewardToken_, uint256 ctAssetAmount_) external;

    function previewSwapTokensForReward(
        address ctAssetToken_,
        address rewardToken_,
        uint256 ctAssetAmount_
    ) external view returns (uint256 rewardAmount, bool availableForWithdrawal, bool isRewardToken);

    function getRewardManager() external view returns (address);

    function getTreasury() external view returns (address);
}
