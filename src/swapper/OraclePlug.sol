// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {CONCRETE_USD_DECIMALS} from "../interfaces/Constants.sol";
import {OracleInformation} from "../interfaces/DataTypes.sol";
import {ITokenRegistry} from "../interfaces/ITokenRegistry.sol";
import {IBeraOracle} from "../interfaces/IBeraOracle.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Errors} from "../interfaces/Errors.sol";

contract OraclePlug {
    using Math for uint256;

    ITokenRegistry internal immutable _tokenRegistry;

    // AggregatorV3Interface internal dataFeed;

    constructor(address tokenRegistry_) {
        if (tokenRegistry_ == address(0)) revert Errors.InvalidTokenRegistry();
        _tokenRegistry = ITokenRegistry(tokenRegistry_);
    }

    //no loop here
    //slither-disable-next-line calls-loop
    function _getPriceFromOracle(
        OracleInformation memory oracle
    ) internal view returns (uint256 price, uint8 decimals) {
        // TODO: Maybe also include other Oracle options. Inside the oracle struct there can also be a field for the oracle type.
        // slither-disable-next-line unused-return
        (int256 intPrice, , ) = IBeraOracle(oracle.addr).getPrice(oracle.pair);
        price = SafeCast.toUint256(intPrice);
        decimals = IBeraOracle(oracle.addr).getDecimals(oracle.pair);
    }

    //no loop here
    //slither-disable-next-line calls-loop
    function _convertFromTokenToStable(address token_, uint256 tokenAmount_) internal view returns (uint256) {
        // get oracle faces/IERC4626.solice and decimals
        //no loop here
        //slither-disable-next-line calls-loop
        OracleInformation memory oracle = _tokenRegistry.getOracle(token_);
        (uint256 price, uint8 quoteDecimals) = _getPriceFromOracle(oracle);
        uint8 tokenDecimals = IERC20Metadata(token_).decimals();
        // compute tokenAmount * price, adjusting for denominations
        return
            price.mulDiv(tokenAmount_, 10 ** quoteDecimals, Math.Rounding.Floor).mulDiv(
                10 ** CONCRETE_USD_DECIMALS,
                10 ** tokenDecimals,
                Math.Rounding.Floor
            );
    }
    //(4000 * 10e6

    function _convertFromCtAssetTokenToStable(
        address ctAssetToken_,
        uint256 ctAssetAmount_
    ) internal view returns (uint256 stableAmount) {
        // get asset and amount from ctAssetToken
        IERC4626 vaultToken = IERC4626(ctAssetToken_);
        address asset = vaultToken.asset();
        uint256 assetAmount = vaultToken.convertToAssets(ctAssetAmount_);
        // convert assetAmount to stable
        stableAmount = _convertFromTokenToStable(asset, assetAmount);
    }

    function _convertFromStableToToken(address token_, uint256 stableAmount_) internal view returns (uint256) {
        // get oracle information
        OracleInformation memory oracle = _tokenRegistry.getOracle(token_);
        // retrieve price and decimals
        //no loop here
        //slither-disable-next-line calls-loop
        (uint256 price, uint8 quoteDecimals) = _getPriceFromOracle(oracle);
        uint8 tokenDecimals = IERC20Metadata(token_).decimals();
        // compute stableAmount / price, adjusting for denominations
        return
            stableAmount_.mulDiv(10 ** tokenDecimals, 10 ** CONCRETE_USD_DECIMALS, Math.Rounding.Floor).mulDiv(
                10 ** quoteDecimals,
                price,
                Math.Rounding.Floor
            );
    }

    //slither-disable-next-line dead-code
    function _convertFromStableToCtAssetToken(
        address ctAssetToken_,
        uint256 stableAmount_
    ) internal view returns (uint256 ctAssetAmount) {
        // get asset and amount from ctAssetToken
        IERC4626 vaultToken = IERC4626(ctAssetToken_);
        address asset = vaultToken.asset();
        // convert stableAmount to assetAmount
        uint256 assetAmount = _convertFromStableToToken(asset, stableAmount_);
        // convert assetAmount to ctAssetAmount
        ctAssetAmount = vaultToken.convertToShares(assetAmount);
    }

    // Getter functions

    function getTokenRegistry() public view returns (address) {
        return address(_tokenRegistry);
    }
}
