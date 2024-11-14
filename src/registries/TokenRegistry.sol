// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TokenInformation, OracleInformation, TokenFilterTypes} from "../interfaces/DataTypes.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "../interfaces/Errors.sol";
import {ITokenRegistry} from "../interfaces/ITokenRegistry.sol";

/// @title Token Registry contract
/// @notice This contract is responsible for managing the token registry
/// @dev The contract is Ownable and uses the EnumerableSet library
/// @author Blueprint Finance
contract TokenRegistryEvents {
    event TokenRegistered(address indexed token, bool isReward, OracleInformation oracle);
    event TokenUnregistered(address indexed token);
    event TokenRemoved(address indexed token);
    event IsRewardUpdated(address indexed token, bool isReward);
    event OracleUpdated(address indexed token, address oracle, uint8 decimals, string pair);
}

contract TokenRegistry is ITokenRegistry, TokenRegistryEvents, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal immutable _treasury;
    mapping(address => TokenInformation) private _token;
    EnumerableSet.AddressSet private _listedTokens;

    /// @param owner_ The address of the contract owner.
    constructor(address owner_, address treasury_) Ownable(owner_) {
        if (treasury_ == address(0)) revert Errors.InvalidTreasuryAddress();
        _treasury = treasury_;
    }

    // Setter functions

    /// @notice Registers a token with the registry.
    /// @param tokenAddress_ The address of the token.
    /// @param isReward_ True if the token is a reward token.
    /// @param oracleAddr_ The address of the oracle.
    /// @param oracleDecimals_ The number of decimals for the oracle.
    /// @param oraclePair_ The pair for the oracle.
    /// @dev Important note: The treasury should approve the spendings for the swapper.
    function registerToken(
        address tokenAddress_,
        bool isReward_,
        address oracleAddr_,
        uint8 oracleDecimals_,
        string memory oraclePair_
    ) external override(ITokenRegistry) onlyOwner {
        if (isRegistered(tokenAddress_)) revert Errors.TokenAlreadyRegistered(tokenAddress_);

        OracleInformation memory oracleInfo = OracleInformation({
            addr: oracleAddr_,
            decimals: oracleDecimals_,
            pair: oraclePair_
        });

        _token[tokenAddress_] = TokenInformation({isRegistered: true, isReward: isReward_, oracle: oracleInfo});

        if (!_listedTokens.add(tokenAddress_)) revert Errors.AdditionFail();

        // emit event
        emit TokenRegistered(tokenAddress_, isReward_, oracleInfo);
    }

    /// @notice Removes a token from the registry.
    /// @param tokenAddress_ The address of the token.
    function removeToken(
        address tokenAddress_
    ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {
        delete _token[tokenAddress_];
        // remove token from the _listedTokens
        if (!_listedTokens.remove(tokenAddress_)) revert Errors.RemoveFail();
        emit TokenRemoved(tokenAddress_);
    }

    /// @notice Unregisters a token from the registry.
    /// @param tokenAddress_ The address of the token.
    function unregisterToken(
        address tokenAddress_
    ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {
        _token[tokenAddress_].isRegistered = false;
        emit TokenUnregistered(tokenAddress_);
    }

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
    ) external override(ITokenRegistry) onlyOwner onlyRegisteredToken(tokenAddress_) {
        _token[tokenAddress_].oracle = OracleInformation({
            addr: oracleAddr_,
            decimals: oracleDecimals_,
            pair: oraclePair_
        });

        emit OracleUpdated(tokenAddress_, oracleAddr_, oracleDecimals_, oraclePair_);
    }

    /// @notice Updates if a token is a reward token.
    /// @param tokenAddress_ The address of the token.
    /// @param isReward_ True if the token is a reward token.
    function updateIsReward(address tokenAddress_, bool isReward_) external override(ITokenRegistry) onlyOwner {
        if (!isRegistered(tokenAddress_) && isReward_) {
            revert Errors.UnregisteredTokensCannotBeRewards(tokenAddress_); // check if token is registered
        }
        _token[tokenAddress_].isReward = isReward_;
        emit IsRewardUpdated(tokenAddress_, isReward_);
    }

    /// Getter functions  ///////////////////////////////

    /// @notice Retrieves the oracle information for a token.
    /// @param tokenAddress_ The address of the token.
    /// @return The oracle information for the token.
    function getOracle(
        address tokenAddress_
    ) external view override(ITokenRegistry) returns (OracleInformation memory) {
        return _token[tokenAddress_].oracle;
    }

    /// @notice Checks if a token is registered.
    /// @param tokenAddress_ The address of the token.
    /// @return True if the token is registered.
    function isRegistered(address tokenAddress_) public view returns (bool) {
        return _token[tokenAddress_].isRegistered;
    }

    /// @notice Checks if a token is a reward token.
    /// @param tokenAddress_ The address of the token.
    /// @return True if the token is a reward token.
    function isRewardToken(address tokenAddress_) public view returns (bool) {
        return _token[tokenAddress_].isReward;
    }

    /// @notice Retrieves the token information.
    function getTokens() public view override(ITokenRegistry) returns (address[] memory) {
        return _listedTokens.values();
    }

    /// @notice Retrieves the token information for a subset of tokens.
    /// @param subset The subset of tokens to retrieve.
    /// @return The subset of tokens.
    function getSubsetOfTokens(
        TokenFilterTypes subset
    ) external view override(ITokenRegistry) returns (address[] memory) {
        address[] memory tokens = getTokens();
        uint256 count = 0;
        for (uint256 i = 0; i < tokens.length; ) {
            if (subset == TokenFilterTypes.isRegistered && isRegistered(tokens[i])) {
                count++;
            } else if (subset == TokenFilterTypes.isReward && isRewardToken(tokens[i])) {
                count++;
            }
            unchecked {
                i++;
            }
        }
        address[] memory subsetTokens = new address[](count);
        count = 0;
        for (uint256 i = 0; i < tokens.length; ) {
            if (subset == TokenFilterTypes.isRegistered && isRegistered(tokens[i])) {
                subsetTokens[count] = tokens[i];
                count++;
            } else if (subset == TokenFilterTypes.isReward && isRewardToken(tokens[i])) {
                subsetTokens[count] = tokens[i];
                count++;
            }
            unchecked {
                i++;
            }
        }
        return subsetTokens;
    }

    /// @notice Retrieves the treasury address.
    /// @return The address of the treasury.
    function getTreasury() public view returns (address) {
        return _treasury;
    }

    // Modifiers ///////////////////////////////////////

    /// @notice Modifier to check if a token is registered.
    /// @param tokenAddress_ The address of the token.
    modifier onlyRegisteredToken(address tokenAddress_) {
        if (!isRegistered(tokenAddress_)) revert Errors.TokenNotRegistered(tokenAddress_);
        _;
    }
}
