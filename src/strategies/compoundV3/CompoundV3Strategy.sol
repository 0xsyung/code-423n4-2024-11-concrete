// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {StrategyBase} from "../StrategyBase.sol";
import {ICToken, ICometRewarder, RewardConfig} from "./ICompoundV3.sol";

/// @title CompoundV3Strategy
/// @notice Strategy for interacting with Compound V3 protocol to optimize yield farming.
//It does implement the functions of the IStrategy interface
//slither-disable-next-line unimplemented-functions
contract CompoundV3Strategy is StrategyBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    ICToken public immutable cToken;
    ICometRewarder public immutable rewarder;

    error AssetDivergence(address);
    error SupplyPaused();
    error WithdrawPaused();

    /// @notice Constructs the CompoundV3Strategy
    /// @param baseAsset_ The base asset of the strategy
    /// @param feeRecipient_ The recipient of fees collected by the strategy
    /// @param owner_ The owner of the strategy
    /// @param rewardFee_ The fee percentage for the reward tokens
    /// @param compoundRewarder_ The address of the Compound rewarder
    /// @param cToken_ The Compound token associated with the base asset
    constructor(
        IERC20 baseAsset_,
        address feeRecipient_,
        address owner_,
        uint256 rewardFee_,
        address compoundRewarder_,
        address cToken_,
        address vault_
    ) {
        IERC20Metadata metaERC20 = IERC20Metadata(address(baseAsset_));

        cToken = ICToken(cToken_);
        rewarder = ICometRewarder(compoundRewarder_);

        __StrategyBase_init(
            baseAsset_,
            string.concat("Concrete Earn CompoundV3 ", metaERC20.symbol(), " Strategy"),
            string.concat("ctCM3-", metaERC20.symbol()),
            feeRecipient_,
            type(uint256).max,
            owner_,
            _getRewardTokens(rewardFee_),
            vault_
        );

        address baseToken = cToken.baseToken();
        if (asset() != baseToken) revert AssetDivergence(baseToken);

        //slither-disable-next-line unused-return
        IERC20(asset()).approve(address(cToken_), type(uint256).max);
    }

    function isProtectStrategy() external pure returns (bool) {
        return false;
    }

    function getAvailableAssetsForWithdrawal() external view returns (uint256) {
        return cToken.balanceOf(address(this));
    }

    /// @notice Returns the total assets under management
    /// @return Total assets under management
    function _totalAssets() internal view override returns (uint256) {
        return cToken.balanceOf(address(this));
    }

    /// @notice Retrieves the addresses of the reward tokens
    /// @return _rewardTokens Array of reward token addresses
    function getRewardTokenAddresses() public view override returns (address[] memory _rewardTokens) {
        RewardConfig memory rewardConfig = rewarder.rewardConfig(address(cToken));
        _rewardTokens = new address[](1);
        _rewardTokens[0] = rewardConfig.token;
    }

    /// @notice Deposits assets into the Compound protocol
    /// @param amount_ The amount of assets to deposit
    function _protocolDeposit(uint256 amount_, uint256) internal virtual override {
        if (cToken.isSupplyPaused()) revert SupplyPaused();
        cToken.supply(asset(), amount_);
    }

    /// @notice Withdraws assets from the Compound protocol
    /// @param amount_ The amount of assets to withdraw
    function _protocolWithdraw(uint256 amount_, uint256) internal virtual override {
        if (cToken.isWithdrawPaused()) revert WithdrawPaused();
        cToken.withdraw(asset(), amount_);
    }

    function _getRewardsToStrategy(bytes memory) internal override {
        try rewarder.claim(address(cToken), address(this), true) {} catch {}
    }

    /**
     * @dev Handles the rewards on withdraw.
     * This function is called before withdrawing assets from the protocol.
     */
    function _handleRewardsOnWithdraw() internal override {
        _getRewardsToStrategy("");
    }

    /// @notice Retires the strategy and withdraws all assets
    function retireStrategy() external onlyOwner {
        _handleRewardsOnWithdraw();
        _protocolWithdraw(cToken.balanceOf(address(this)), 0);
    }
}
