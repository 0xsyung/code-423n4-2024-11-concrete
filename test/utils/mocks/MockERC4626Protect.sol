//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626, ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IMockProtectStrategy} from "../../../src/interfaces/IMockProtectStrategy.sol";

contract MockERC4626Protect is ERC4626 {
    bool public isProtectStrategy = true;

    uint256 public highWatermark = 0;
    uint256 public borrowDebt = 0;

    using SafeERC20 for IERC20;
    using Math for uint256;

    uint8 internal _decimals;
    uint8 public constant decimalOffset = 9;

    constructor(
        IERC20 asset_,
        string memory shareName_,
        string memory shareSymbol_
    ) ERC4626(IERC20Metadata(address(asset_))) ERC20(shareName_, shareSymbol_) {
        _decimals = IERC20Metadata(address(asset_)).decimals() + decimalOffset;
    }

    function decimals() public view override(ERC4626) returns (uint8) {
        return _decimals;
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256 shares) {
        return assets.mulDiv(totalSupply() + 10 ** decimalOffset, totalAssets() + 1, rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** decimalOffset, rounding);
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function getAvailableAssetsForWithdrawal() public view virtual returns (uint256) {
        //TODO: This will be changed to return the actual available assets for withdrawal
        return IERC20(asset()).balanceOf(address(this));
    }

    function setAvailableAssetsZero(bool _avaliableAssetsZero) public virtual {}

    function executeBorrowClaim(uint256 amount, address recipient) external {}

    function setHighWatermark(uint256 highWatermark_) external {
        highWatermark = highWatermark_;
    }

    function getBorrowDebt() public view virtual returns (uint256) {
        return borrowDebt;
    }

    function updateBorrowDebt(uint256 amount_) external virtual {
        //the real funtion just substracts the amount from the borrowDebt
        borrowDebt = amount_;
    }

    function lendFunds(uint256 amount_) external virtual {
        borrowDebt += amount_;
        IERC20(asset()).transfer(msg.sender, amount_);
    }

    function totalAssets() public view override returns (uint256) {
        return borrowDebt + IERC20(asset()).balanceOf(address(this));
    }
}
