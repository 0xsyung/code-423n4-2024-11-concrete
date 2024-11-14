//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IBeraOracle} from "../../../src/interfaces/IBeraOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockBeraOracle is IBeraOracle {
    mapping(string => int256) public prices;
    mapping(string => uint256) public timestamps;
    mapping(string => uint64) public values;
    mapping(string => uint8) public decimals;
    string[] public currencyPairs;

    function addCurrencyPairs(string[] calldata pairs) external override returns (bool) {
        for (uint256 i = 0; i < pairs.length; i++) {
            currencyPairs.push(pairs[i]);
        }
        emit CurrencyPairsAdded(pairs);
        return true;
    }

    function getAllCurrencyPairs() external view override returns (string[] memory) {
        return currencyPairs;
    }

    function getDecimals(string calldata pair) external view override returns (uint8) {
        return decimals[pair];
    }

    function getPrice(string calldata pair) external view override returns (int256, uint256, uint64) {
        return (prices[pair], timestamps[pair], values[pair]);
    }

    function hasCurrencyPair(string calldata pair) external view override returns (bool) {
        return prices[pair] != 0;
    }

    function removeCurrencyPairs(string[] calldata pairs) external override returns (bool) {
        for (uint256 i = 0; i < pairs.length; i++) {
            for (uint256 j = 0; j < currencyPairs.length; j++) {
                if (keccak256(abi.encodePacked(currencyPairs[j])) == keccak256(abi.encodePacked(pairs[i]))) {
                    currencyPairs[j] = currencyPairs[currencyPairs.length - 1];
                    currencyPairs.pop();
                }
            }
        }
        emit CurrencyPairsRemoved(pairs);
        return true;
    }

    function setPriceDecimalsAndTimestamp(
        string calldata pair,
        int256 price,
        uint8 decimal,
        uint256 timestamp
    ) external {
        prices[pair] = price;
        decimals[pair] = decimal;
        timestamps[pair] = timestamp;
    }
}
