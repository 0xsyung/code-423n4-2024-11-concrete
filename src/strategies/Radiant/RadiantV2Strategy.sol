//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC20, IERC20Metadata, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {StrategyBase} from "../StrategyBase.sol";
import {DataTypes} from "./DataTypes.sol";
import {IAToken, IChefIncentivesController, ILendingPoolAddressesProvider, ILendingPool} from "./IRadiantV2.sol";

//It does implement the functions of the IStrategy interface
//slither-disable-next-line unimplemented-functions
contract RadiantV2Strategy is StrategyBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    ILendingPoolAddressesProvider public immutable addressesProvider;
    IChefIncentivesController public immutable incentiveController;
    ILendingPool public immutable lendingPool;
    IAToken public immutable rToken;
    // the current strategy is not eligible for rdnt rewards but in future if this is changed then this flag will be used
    bool public rewardsEnabled;

    error AssetDivergence();
    error ZeroAddress();

    event SetEnableRewards(address indexed sender, bool rewardsEnabled);

    constructor(
        IERC20 baseAsset_,
        address feeRecipient_,
        address owner_,
        uint256 rewardFee_,
        address addressesProvider_,
        address vault_
    ) {
        if (addressesProvider_ == address(0)) revert ZeroAddress();

        IERC20Metadata metaERC20 = IERC20Metadata(address(baseAsset_));

        addressesProvider = ILendingPoolAddressesProvider(addressesProvider_);
        lendingPool = ILendingPool(addressesProvider.getLendingPool());
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(address(baseAsset_));
        rToken = IAToken(reserveData.aTokenAddress);
        if (rToken.UNDERLYING_ASSET_ADDRESS() != address(baseAsset_)) revert AssetDivergence();

        rewardsEnabled = false;
        incentiveController = IChefIncentivesController(rToken.getIncentivesController());

        __StrategyBase_init(
            baseAsset_,
            string.concat("Concrete Earn RadiantV2 ", metaERC20.symbol(), " Strategy"),
            string.concat("ctRdV2-", metaERC20.symbol()),
            feeRecipient_,
            type(uint256).max,
            owner_,
            _getRewardTokens(rewardFee_),
            vault_
        );
        // at contract creation: It is assumed that the initial allowance is 0
        //slither-disable-next-line unused-return
        baseAsset_.safeIncreaseAllowance(address(lendingPool), type(uint256).max);
    }

    function isProtectStrategy() external pure returns (bool) {
        return false;
    }

    function getAvailableAssetsForWithdrawal() external view returns (uint256) {
        return rToken.balanceOf(address(this));
    }

    /**
     * @dev Returns the total assets under management in this strategy.
     * @return The total amount of assets in the strategy.
     */
    function _totalAssets() internal view override returns (uint256) {
        return rToken.balanceOf(address(this));
    }

    /**
     * @dev Retrieves the addresses of reward tokens available for this strategy.
     * @return An array of addresses of reward tokens.
     */
    function getRewardTokenAddresses() public view override returns (address[] memory) {
        if (!rewardsEnabled) return new address[](0);
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = incentiveController.rdntToken();
        return _rewardTokens;
    }

    /**
     * @dev Deposits assets into the Aave protocol.
     * @param amount_ The amount of assets to deposit.
     */
    function _protocolDeposit(uint256 amount_, uint256) internal virtual override {
        lendingPool.deposit(asset(), amount_, address(this), 0);
    }

    /**
     * @dev Withdraws assets from the Aave protocol.
     * @param amount_ The amount of assets to withdraw.
     */
    function _protocolWithdraw(uint256 amount_, uint256) internal virtual override {
        //slither-disable-next-line unused-return
        lendingPool.withdraw(asset(), amount_, address(this));
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
        uint256 amountToWithdraw = rToken.balanceOf(address(this));
        if (amountToWithdraw > 0) {
            _protocolWithdraw(amountToWithdraw, 0);
        }
    }

    function _getRewardsToStrategy(bytes memory) internal override {
        if (!rewardsEnabled) return;
        if (address(incentiveController) == address(0)) return;
        address[] memory _assets = new address[](1);
        _assets[0] = address(rToken);

        //slither-disable-next-line unused-return
        try incentiveController.claim(address(this), _assets) {} catch {}
    }

    /**
     * @dev by setting rewardsEnabled to true the strategy will be able to handle rdnt rewards.
     * check the eligibility criteria before enabling rewards here:
     * https://docs.radiant.capital/radiant/project-info/dlp/eligibility
     */
    function setEnableRewards(bool _rewardsEnabled) external onlyOwner {
        rewardsEnabled = _rewardsEnabled;
        emit SetEnableRewards(msg.sender, _rewardsEnabled);
    }
}
