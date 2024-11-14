//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626Upgradeable, IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StrategyBase, RewardToken} from "../../../src/strategies/StrategyBase.sol";
import {MockERC20} from "..//mocks/MockERC20.sol";

contract ExampleStrategyBaseImplementation is StrategyBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    constructor(
        IERC20 asset_,
        string memory shareName_,
        string memory shareSymbol_,
        address feeRecipient_,
        uint256 depositLimit_,
        address owner_,
        RewardToken[] memory rewardTokens_,
        address vault_
    ) {
        __StrategyBase_init(
            asset_,
            shareName_,
            shareSymbol_,
            feeRecipient_,
            depositLimit_,
            owner_,
            rewardTokens_,
            vault_
        );
    }

    function decimals() public view override(IERC20Metadata, ERC4626Upgradeable) returns (uint8) {
        return _decimals;
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256 shares) {
        return assets.mulDiv(totalSupply() + 10 ** DECIMAL_OFFSET, totalAssets() + 1, rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** DECIMAL_OFFSET, rounding);
    }

    function deposit(
        uint256 assets_,
        address receiver_
    ) public override(IERC4626, ERC4626Upgradeable) nonReentrant whenNotPaused returns (uint256 shares) {
        if (receiver_ == address(0)) revert InvalidRecipient();
        if (assets_ > maxDeposit(receiver_) || assets_ > depositLimit) revert MaxError();

        // Calculate the net shares to mint for the deposited assets
        shares = _convertToShares(assets_, Math.Rounding.Floor);
        //slither-disable-next-line incorrect-equality
        if (shares == 0) revert ZeroAmount();

        _mint(receiver_, shares);

        // Transfer the assets from the sender to the vault
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets_);

        emit Deposit(msg.sender, receiver_, assets_, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626Upgradeable) returns (uint256 shares) {
        // if (caller != owner) {
        //     _spendAllowance(owner, caller, shares);
        // }
        _handleRewardsOnWithdraw();
        shares = _convertToShares(assets, Math.Rounding.Floor);
        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(receiver, receiver, owner, assets, shares);
    }

    function getAvailableAssetsForWithdrawal() public view returns (uint256) {
        //TODO: This will be changed to return the actual available assets for withdrawal
        return IERC20(asset()).balanceOf(address(this));
    }

    function _totalAssets() internal view override returns (uint256) {}

    function _getRewardsToStrategy(bytes memory) internal override {
        uint256 len = rewardTokens.length;
        for (uint256 i = 0; i < len; ) {
            if (i != 2) MockERC20(address(rewardTokens[i].token)).mint(address(this), 20000000);
            unchecked {
                ++i;
            }
        }
    }

    function _protocolDeposit(uint256 assets, uint256 shares) internal override {
        IERC20(asset()).safeTransferFrom(msg.sender, _vault, assets);
        _mint(msg.sender, shares);
    }

    function isProtectStrategy() external pure returns (bool) {
        return false;
    }

    function getRewardTokenAddresses() public view override returns (address[] memory _rewardTokens) {}

    function _handleRewardsOnWithdraw() internal override {
        _getRewardsToStrategy("");
    }
}
