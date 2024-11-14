//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC20, IERC20Metadata, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EasyMathV2} from "./EasyMathV2.sol";

import {StrategyBase, RewardToken} from "../StrategyBase.sol";
import {ISilo, ISiloRepository, ISiloIncentivesController} from "./ISiloV1.sol";

struct ConstructorTemp {
    address[] siloAssets;
    address[] rewards;
    ISilo.AssetStorage assetStorage;
    RewardToken[] rewardTokenArray;
    uint256 length;
    uint256 i;
}

//It does implement the functions of the IStrategy interface
//slither-disable-next-line unimplemented-functions
contract SiloV1Strategy is StrategyBase {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using EasyMathV2 for uint256;

    ISilo public immutable silo;
    ISiloRepository public immutable siloRepository;
    IERC20 public immutable collateralToken;
    ISiloIncentivesController public immutable siloIncentivesController;

    error AssetDivergence();
    error ZeroAddress();

    constructor(
        IERC20Metadata baseAsset_,
        address feeRecipient_,
        address owner_,
        uint256 rewardFee_,
        address siloAsset_,
        address siloRepository_,
        address siloIncentivesController_,
        address[] memory extraRewardAssets,
        uint256[] memory extraRewardFees,
        address vault_
    ) {
        //slither-disable-next-line uninitialized-local
        ConstructorTemp memory temp;

        if (siloRepository_ == address(0)) revert ZeroAddress();
        if (siloIncentivesController_ == address(0)) revert ZeroAddress();

        siloRepository = ISiloRepository(siloRepository_);
        silo = ISilo(siloRepository.getSilo(siloAsset_));
        if (address(silo) == address(0)) revert ZeroAddress();
        // validate the bridge asset
        if (siloAsset_ != address(baseAsset_)) {
            temp.siloAssets = silo.getAssets();
            temp.length = temp.siloAssets.length;
            while (temp.i < temp.length) {
                if (temp.siloAssets[temp.i] == address(baseAsset_)) {
                    break;
                }
                unchecked {
                    temp.i++;
                }
            }
            if (temp.i == temp.length) revert AssetDivergence();
        }
        siloIncentivesController = ISiloIncentivesController(siloIncentivesController_);
        temp.assetStorage = silo.assetStorage(address(baseAsset_));
        collateralToken = IERC20(temp.assetStorage.collateralToken);

        // prepare rewardTokens array

        temp.length = extraRewardAssets.length;
        temp.rewardTokenArray = new RewardToken[](temp.length + 1);
        // assign the silo reward token first and then process the extra reward tokens
        temp.rewardTokenArray[0] = RewardToken(IERC20(getRewardTokenAddresses()[0]), rewardFee_, 0);

        for (temp.i = 0; temp.i < temp.length; ) {
            temp.rewardTokenArray[temp.i + 1] = RewardToken(
                IERC20(extraRewardAssets[temp.i]),
                extraRewardFees[temp.i],
                0
            );
            unchecked {
                temp.i++;
            }
        }

        if (address(collateralToken) == address(0)) revert InvalidAssetAddress();
        __StrategyBase_init(
            IERC20(baseAsset_),
            string.concat("Concrete Earn SiloV1 ", baseAsset_.symbol(), " Strategy"),
            string.concat("ctSlV1-", baseAsset_.symbol()),
            feeRecipient_,
            type(uint256).max,
            owner_,
            temp.rewardTokenArray,
            vault_
        );
        // at contract creation: It is assumed that the initial allowance is 0
        //slither-disable-next-line unused-return
        IERC20(baseAsset_).safeIncreaseAllowance(address(silo), type(uint256).max);
    }

    function isProtectStrategy() external pure returns (bool) {
        return false;
    }

    function getAvailableAssetsForWithdrawal() external view returns (uint256) {
        uint256 shares = collateralToken.balanceOf(address(this));
        return shares;
        // return balanceOfUnderlying(shares);
    }

    /**
     * @dev Returns the total assets under management in this strategy.
     * @return The total amount of assets in the strategy.
     */
    function _totalAssets() internal view override returns (uint256) {
        uint256 shares = collateralToken.balanceOf(address(this));
        return shares;
        // return balanceOfUnderlying(shares);
    }

    /**
     * @dev Retrieves the addresses of reward tokens available for this strategy.
     * @return An array of addresses of reward tokens.
     */
    function getRewardTokenAddresses() public view override returns (address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = siloIncentivesController.REWARD_TOKEN();
        return _rewardTokens;
    }

    /**
     * @dev Deposits assets into the Aave protocol.
     * @param amount_ The amount of assets to deposit.
     */
    function _protocolDeposit(uint256 amount_, uint256) internal virtual override {
        //slither-disable-next-line unused-return
        silo.deposit(asset(), amount_, false);
    }

    /**
     * @dev Withdraws assets from the Aave protocol.
     * @param amount_ The amount of assets to withdraw.
     */
    function _protocolWithdraw(uint256 amount_, uint256) internal virtual override {
        //slither-disable-next-line unused-return
        silo.withdraw(asset(), amount_, false);
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
        uint256 shares = collateralToken.balanceOf(address(this));
        uint256 amountToWithdraw = balanceOfUnderlying(shares);
        if (amountToWithdraw > 0) {
            _protocolWithdraw(amountToWithdraw, 0);
        }
    }

    function _getRewardsToStrategy(bytes memory) internal override {
        if (address(siloIncentivesController) == address(0)) return;
        address[] memory _assets = new address[](1);
        _assets[0] = address(collateralToken);

        uint256 rewardAmount = siloIncentivesController.getRewardsBalance(_assets, address(this));
        if (rewardAmount == 0) return;
        //slither-disable-next-line unused-return
        try siloIncentivesController.claimRewards(_assets, rewardAmount, address(this)) {} catch {}
    }

    function balanceOfUnderlying(uint256 shares) public view returns (uint256) {
        ISilo.AssetStorage memory assetStorage = silo.assetStorage(asset());
        return shares.toAmount(assetStorage.totalDeposits, collateralToken.totalSupply());
    }
}
