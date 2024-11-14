//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {OracleInformation, TokenFilterTypes} from "../interfaces/DataTypes.sol";

/// @title ITokenRegistry
/// @notice This interface defines the functions for the TokenRegistry contract.
interface ITokenRegistry {
    /// @notice Registers a token with the registry.
    /// @param tokenAddress_ The address of the token.
    /// @param isReward_ True if the token is a reward token.
    /// @param oracleAddr_ The address of the oracle.
    /// @param oracleDecimals_ The number of decimals for the oracle.
    /// @param oraclePair_ The pair for the oracle.
    function registerToken(
        address tokenAddress_,
        bool isReward_,
        address oracleAddr_,
        uint8 oracleDecimals_,
        string memory oraclePair_
    ) external;

    /// @notice Removes a token from the registry.
    /// @param tokenAddress_ The address of the token.
    function removeToken(address tokenAddress_) external;

    /// @notice Unregisters a token from the registry.
    /// @param tokenAddress_ The address of the token.
    function unregisterToken(address tokenAddress_) external;

    /// @notice Updates the oracle information for a token.
    /// @param tokenAddress_ The address of the token.
    /// @param oracleAddr_ The address of the oracle.
    /// @param oracleDecimals_ The number of decimals for the oracle.
    /// @param oraclePair_ The pair for the oracle.
    function updateOracle(
        address tokenAddress_,
        address oracleAddr_,
        uint8 oracleDecimals_,
        string memory oraclePair_
    ) external;

    /// @notice Updates if a token is a reward token.
    /// @param tokenAddress_ The address of the token.
    /// @param isReward_ True if the token is a reward token.
    function updateIsReward(address tokenAddress_, bool isReward_) external;

    /// @notice Retrieves the oracle information for a token.
    /// @param tokenAddress_ The address of the token.
    /// @return The oracle information for the token.
    function getOracle(address tokenAddress_) external view returns (OracleInformation memory);

    /// @notice Checks if a token is registered.
    /// @param tokenAddress_ The address of the token.
    /// @return True if the token is registered.
    function isRegistered(address tokenAddress_) external view returns (bool);

    /// @notice Checks if a token is a reward token.
    /// @param tokenAddress_ The address of the token.
    /// @return True if the token is a reward token.
    function isRewardToken(address tokenAddress_) external view returns (bool);

    /// @notice Retrieves the list of registered tokens.
    /// @return The list of registered tokens.
    function getTokens() external view returns (address[] memory);

    /// @notice Retrieves the token information for a subset of tokens.
    /// @param subset The subset of tokens to retrieve.
    /// @return The subset of tokens.
    function getSubsetOfTokens(TokenFilterTypes subset) external view returns (address[] memory);
}
