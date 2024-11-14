//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {StrategyBase} from "../StrategyBase.sol";
import {ILendingPool, IAaveIncentives, IAToken, IProtocolDataProvider} from "./IAaveV3.sol";

//It does implement the functions of the IStrategy interface
//slither-disable-next-line unimplemented-functions

contract AaveV3Strategy is StrategyBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IAToken public immutable aToken;
    IAaveIncentives public immutable aaveIncentives;
    ILendingPool public immutable lendingPool;

    error AssetDivergence();

    constructor(
        IERC20 baseAsset_,
        address feeRecipient_,
        address owner_,
        uint256 rewardFee_,
        address aaveDataProvider_,
        address vault_
    ) {
        IERC20Metadata metaERC20 = IERC20Metadata(address(baseAsset_));

        //slither-disable-next-line unused-return
        (address _aToken, , ) = IProtocolDataProvider(aaveDataProvider_).getReserveTokensAddresses(address(baseAsset_));
        aToken = IAToken(_aToken);
        if (aToken.UNDERLYING_ASSET_ADDRESS() != address(baseAsset_)) {
            revert AssetDivergence();
        }

        aaveIncentives = IAaveIncentives(aToken.getIncentivesController());
        lendingPool = ILendingPool(aToken.POOL());

        __StrategyBase_init(
            baseAsset_,
            string.concat("Concrete Earn AaveV3 ", metaERC20.symbol(), " Strategy"),
            string.concat("ctAv3-", metaERC20.symbol()),
            feeRecipient_,
            type(uint256).max,
            owner_,
            _getRewardTokens(rewardFee_),
            vault_
        );
        //slither-disable-next-line unused-return
        baseAsset_.approve(address(lendingPool), type(uint256).max);
    }

    function isProtectStrategy() external pure returns (bool) {
        return false;
    }

    function getAvailableAssetsForWithdrawal() external view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /**
     * @dev Returns the total assets under management in this strategy.
     * @return The total amount of assets in the strategy.
     */
    function _totalAssets() internal view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /**
     * @dev Retrieves the addresses of reward tokens available for this strategy.
     * @return An array of addresses of reward tokens.
     */
    function getRewardTokenAddresses() public view override returns (address[] memory) {
        return aaveIncentives.getRewardsByAsset(address(aToken));
    }

    /**
     * @dev Deposits assets into the Aave protocol.
     * @param assets_ The amount of assets to deposit.
     */
    function _protocolDeposit(uint256 assets_, uint256) internal virtual override {
        lendingPool.supply(asset(), assets_, address(this), 0);
    }

    /**
     * @dev Withdraws assets from the Aave protocol.
     * @param assets_ The amount of assets to withdraw.
     */
    function _protocolWithdraw(uint256 assets_, uint256) internal virtual override {
        //slither-disable-next-line unused-return
        lendingPool.withdraw(asset(), assets_, address(this));
    }

    /**
     * @dev Handles the rewards on withdraw.
     * This function is called before withdrawing assets from the protocol.
     */
    function _handleRewardsOnWithdraw() internal override {
        _getRewardsToStrategy("");
    }

    /**
     * @dev Withdraws all assets from the Aave protocol and retires the strategy.
     * This function can only be called by the owner of the strategy.
     */
    function retireStrategy() external onlyOwner {
        _handleRewardsOnWithdraw();
        _protocolWithdraw(aToken.balanceOf(address(this)), 0);
    }

    function _getRewardsToStrategy(bytes memory) internal override {
        if (address(aaveIncentives) == address(0)) return;

        address[] memory _assets = new address[](1);
        _assets[0] = address(aToken);

        //slither-disable-next-line unused-return
        try aaveIncentives.claimAllRewards(_assets, address(this)) {} catch {}
    }
}
