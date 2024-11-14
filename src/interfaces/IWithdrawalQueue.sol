//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

interface IWithdrawalQueue {
    function requestWithdrawal(address recipient, uint256 amount) external;
    function prepareWithdrawal(
        uint256 _requestId,
        uint256 _avaliableAssets
    ) external returns (address recipient, uint256 amount, uint256 avaliableAssets);

    function unfinalizedAmount() external view returns (uint256);
    function getLastFinalizedRequestId() external view returns (uint256);
    function getLastRequestId() external view returns (uint256);
    //slither-disable-next-line naming-convention
    function _finalize(uint256 _lastRequestIdToBeFinalized) external;
}
