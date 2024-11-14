// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWithdrawalQueue} from "../interfaces/IWithdrawalQueue.sol";
/// @title WithdrawalQueue
/// @notice Queue for storing and managing withdrawal requests.
///         This contract is based on Lido's WithdrawalQueue and has been
///         modified to support Blast specific logic such as withdrawal discounts.

contract WithdrawalQueue is Ownable, IWithdrawalQueue {
    using EnumerableSet for EnumerableSet.UintSet;

    WithdrawalRequest[] private _requests;
    mapping(address => EnumerableSet.UintSet) private _requestsByOwner;
    uint256 private lastRequestId;
    uint256 private lastFinalizedRequestId;

    /// @notice structure representing a request for withdrawal
    struct WithdrawalRequest {
        /// @notice sum of the all tokens submitted for withdrawals including this request (nominal amount)
        uint128 cumulativeAmount;
        /// @notice address that can claim the request and receives the funds
        address recipient;
        /// @notice block.timestamp when the request was created
        uint40 timestamp;
        /// @notice flag if the request was claimed
        bool claimed;
    }

    /// @notice output format struct for `_getWithdrawalStatus()` method
    struct WithdrawalRequestStatus {
        /// @notice nominal token amount that was locked on withdrawal queue for this request
        uint256 amount;
        /// @notice address that can claim or transfer this request
        address recipient;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is claimed
        bool isClaimed;
    }

    /// @dev amount represents the nominal amount of tokens that were withdrawn (burned) on L2.
    event WithdrawalRequested(
        uint256 indexed requestId,
        address indexed requestor,
        address indexed recipient,
        uint256 amount
    );

    /// @dev amount represents the real amount of ETH that was transferred to the recipient.
    event WithdrawalClaimed(uint256 indexed requestId, address indexed recipient, uint256 amount);

    /// @dev amountOfETHLocked represents the real amount of ETH that was locked in the queue and will be
    ///      transferred to the recipient on claim.
    event WithdrawalsFinalized(uint256 indexed from, uint256 indexed to, uint256 timestamp);

    error InvalidRequestId(uint256 _requestId);
    error InvalidRequestIdRange(uint256 startId, uint256 endId);
    error RequestNotFoundOrNotFinalized(uint256 _requestId);
    error RequestAlreadyClaimed(uint256 _requestId);

    constructor(address vault) Ownable(vault) {
        _requests.push(WithdrawalRequest(0, address(0), uint40(block.timestamp), true));
    }

    //slither-disable-next-line naming-convention
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses) {
        statuses = new WithdrawalRequestStatus[](_requestIds.length);
        for (uint256 i = 0; i < _requestIds.length; ) {
            statuses[i] = _getStatus(_requestIds[i]);
            unchecked {
                i++;
            }
        }
    }

    //slither-disable-next-line naming-convention
    function getWithdrawalRequests(address _owner) external view virtual returns (uint256[] memory requestIds) {
        return _requestsByOwner[_owner].values();
    }

    /// @notice id of the last request
    ///  NB! requests are indexed from 1, so it returns 0 if there is no requests in the queue
    function getLastRequestId() public view virtual returns (uint256) {
        return lastRequestId;
    }

    /// @notice id of the last finalized request
    ///  NB! requests are indexed from 1, so it returns 0 if there is no finalized requests in the queue
    function getLastFinalizedRequestId() public view virtual returns (uint256) {
        return lastFinalizedRequestId;
    }

    /// @notice return the number of unfinalized requests in the queue
    function unfinalizedRequestNumber() public view virtual returns (uint256) {
        return lastRequestId - lastFinalizedRequestId;
    }

    /// @notice Returns the amount of ETH in the queue yet to be finalized
    ///  NB! this is the nominal amount of ETH burned on L2
    //TODO test this function
    function unfinalizedAmount() external view virtual onlyOwner returns (uint256) {
        return _requests[lastRequestId].cumulativeAmount - _requests[lastFinalizedRequestId].cumulativeAmount;
    }

    /// @dev Returns the status of the withdrawal request with `_requestId` id
    function _getStatus(uint256 _requestId) internal view virtual returns (WithdrawalRequestStatus memory status) {
        if (_requestId == 0 || _requestId > lastRequestId) revert InvalidRequestId(_requestId);

        WithdrawalRequest memory request = _requests[_requestId];
        WithdrawalRequest memory previousRequest = _requests[_requestId - 1];

        status = WithdrawalRequestStatus(
            request.cumulativeAmount - previousRequest.cumulativeAmount,
            request.recipient,
            request.timestamp,
            request.claimed
        );
    }

    /// @dev creates a new `WithdrawalRequest` in the queue
    ///  Emits WithdrawalRequested event
    //TODO test this function
    function requestWithdrawal(address recipient, uint256 amount) external virtual onlyOwner {
        uint256 _lastRequestId = lastRequestId;
        WithdrawalRequest memory lastRequest = _requests[_lastRequestId];

        uint128 cumulativeAmount = lastRequest.cumulativeAmount + SafeCast.toUint128(amount);
        uint256 requestId = _lastRequestId + 1;
        lastRequestId = requestId;
        WithdrawalRequest memory newRequest = WithdrawalRequest(
            cumulativeAmount,
            recipient,
            uint40(block.timestamp),
            false
        );
        _requests.push(newRequest);
        assert(_requestsByOwner[recipient].add(requestId));
        emit WithdrawalRequested(requestId, msg.sender, recipient, amount);
    }

    /// @dev preapares a request to be transferred
    ///  Emits WithdrawalClaimed event
    //TODO test this function
    //slither-disable-next-line naming-convention
    function prepareWithdrawal(
        uint256 _requestId,
        uint256 _avaliableAssets
    ) external onlyOwner returns (address recipient, uint256 amount, uint256 avaliableAssets) {
        if (_requestId == 0) revert InvalidRequestId(_requestId);
        if (_requestId < lastFinalizedRequestId) revert RequestNotFoundOrNotFinalized(_requestId);

        WithdrawalRequest storage request = _requests[_requestId];

        if (request.claimed) revert RequestAlreadyClaimed(_requestId);

        recipient = request.recipient;

        WithdrawalRequest storage prevRequest = _requests[_requestId - 1];

        amount = request.cumulativeAmount - prevRequest.cumulativeAmount;

        if (_avaliableAssets > amount) {
            assert(_requestsByOwner[recipient].remove(_requestId));
            avaliableAssets = _avaliableAssets - amount;
            request.claimed = true;
            //This is commented to fit the requirements of the vault
            //instead of this we will call _withdrawStrategyFunds
            //IERC20(TOKEN).safeTransfer(recipient, realAmount);

            emit WithdrawalClaimed(_requestId, recipient, amount);
        }
    }

    /// @dev Finalize requests in the queue
    ///  Emits WithdrawalsFinalized event.
    //slither-disable-next-line naming-convention
    function _finalize(uint256 _lastRequestIdToBeFinalized) external onlyOwner {
        if (_lastRequestIdToBeFinalized != 0) {
            if (_lastRequestIdToBeFinalized > lastRequestId) revert InvalidRequestId(_lastRequestIdToBeFinalized);
            uint256 _lastFinalizedRequestId = lastFinalizedRequestId;
            if (_lastRequestIdToBeFinalized <= _lastFinalizedRequestId) {
                revert InvalidRequestId(_lastRequestIdToBeFinalized);
            }

            uint256 firstRequestIdToFinalize = _lastFinalizedRequestId + 1;

            lastFinalizedRequestId = _lastRequestIdToBeFinalized;

            emit WithdrawalsFinalized(firstRequestIdToFinalize, _lastRequestIdToBeFinalized, block.timestamp);
        }
    }
}
