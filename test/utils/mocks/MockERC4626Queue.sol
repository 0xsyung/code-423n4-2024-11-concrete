//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC4626} from "./MockERC4626.sol";
import {ERC4626, ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract MockERC4626Queue is MockERC4626 {
    bool public avaliableAssetsZero = true;

    constructor(
        IERC20 asset_,
        string memory shareName_,
        string memory shareSymbol_
    ) MockERC4626(asset_, shareName_, shareSymbol_) {}

    function setAvailableAssetsZero(bool _avaliableAssetsZero) public override {
        avaliableAssetsZero = _avaliableAssetsZero;
    }

    function getAvailableAssetsForWithdrawal() public view override returns (uint256) {
        if (avaliableAssetsZero) return 0;
        return super.getAvailableAssetsForWithdrawal();
    }
}
