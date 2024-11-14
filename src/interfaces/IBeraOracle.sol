// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

// Interface for the Bera Oracle contract.
/// @title Bera Oracle Interface
/// @notice Interface for the Bera Oracle contract.
/// @dev This interface is used to interact with the Bera Oracle contract.
/// @dev Examples for pairs would be ETH/USDC or BTC/USDC or USDC/USDT.
interface IBeraOracle {
    // Function to add currency pairs. Returns true if successful.
    function addCurrencyPairs(string[] calldata pairs) external returns (bool);

    // Function to retrieve all currency pairs. Returns an array of strings.
    function getAllCurrencyPairs() external view returns (string[] memory);

    // Function to get the decimal precision of a currency pair. Returns an uint8.
    function getDecimals(string calldata pair) external view returns (uint8);

    // Function to get the price of a currency pair. Returns price, timestamp, and another value.
    function getPrice(string calldata pair) external view returns (int256, uint256, uint64);

    // Function to check if a currency pair exists. Returns true if it exists.
    function hasCurrencyPair(string calldata pair) external view returns (bool);

    // Function to remove currency pairs. Returns true if successful.
    function removeCurrencyPairs(string[] calldata pairs) external returns (bool);

    // Event emitted when currency pairs are added.
    event CurrencyPairsAdded(string[] currencyPairs);

    // Event emitted when currency pairs are removed.
    event CurrencyPairsRemoved(string[] currencyPairs);
}
