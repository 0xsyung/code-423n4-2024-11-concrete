//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMetaMorpho} from "../../interfaces/IMorphoVaults.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MorphoV1Helper} from "@blueprint-finance/hub-and-spokes-libraries/src/libraries/MorphoV1Helper.sol";
import {StrategyBase} from "../StrategyBase.sol";

//It does implement the functions of the IStrategy interface
contract MorphoVaultStrategy is StrategyBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IMetaMorpho _morphoVault;

    error AssetDivergence();

    constructor(
        IERC20 baseAsset_,
        address feeRecipient_,
        address owner_,
        uint256 rewardFee_,
        address morphoVault_,
        address vault_
    ) {
        _morphoVault = IMetaMorpho(morphoVault_);

        if (IMetaMorpho(morphoVault_).asset() != address(baseAsset_)) {
            revert AssetDivergence();
        }

        string memory symbol = IMetaMorpho(morphoVault_).symbol();
        __StrategyBase_init(
            baseAsset_,
            string.concat("Concrete Morpho Vault ", symbol, " Strategy"),
            string.concat("ctMV1-", symbol),
            feeRecipient_,
            type(uint256).max,
            owner_,
            _getRewardTokens(rewardFee_),
            vault_
        );
        //slither-disable-next-line unused-return
        baseAsset_.forceApprove(address(morphoVault_), type(uint256).max);
    }

    ///@notice checks whether the strategy is a protect strategy or not
    ///@return false
    function isProtectStrategy() external pure returns (bool) {
        return false;
    }

    function getAvailableAssetsForWithdrawal() external view returns (uint256) {
        return _morphoVault.maxWithdraw(address(this));
    }

    /**
     * @dev Returns the total assets under management in this strategy.
     * @return The total amount of assets in the strategy.
     */
    function _totalAssets() internal view override returns (uint256) {
        return _morphoVault.convertToAssets(_morphoVault.balanceOf(address(this)));
    }

    /**
     * @dev Deposits assets into the Aave protocol.
     * @param assets_ The amount of assets to deposit.
     */
    function _protocolDeposit(uint256 assets_, uint256) internal virtual override {
        // slither-disable-next-line unused-return
        _morphoVault.deposit(assets_, address(this));
    }

    /**
     * @dev Withdraws assets from the Aave protocol.
     * @param assets_ The amount of assets to withdraw.
     */
    function _protocolWithdraw(uint256 assets_, uint256) internal virtual override {
        //slither-disable-next-line unused-return
        _morphoVault.withdraw(assets_, address(this), address(this));
    }

    /**
     * @dev Withdraws all assets from the protocol and retires the strategy.
     * This function can only be called by the owner of the strategy.
     * @dev In the Morpho case there is no reward claim prior to the retire, as it requires the Merkle tree of the reward distribution. It has to be done separately.
     */
    function retireStrategy() external onlyOwner {
        // slither-disable-next-line unused-return
        _morphoVault.withdraw(_morphoVault.maxWithdraw(address(this)), address(this), address(this));
    }

    function _handleRewardsOnWithdraw() internal override {}

    //set to pure to remove warnings
    function _getRewardsToStrategy(bytes memory data) internal override {
        //TODO check the rewards based on the distributor
        if (data.length != 0) {
            MorphoV1Helper.claimRewardsAndSend(address(0), data, 1, false);
        }
    }

    // View functions
    function encodeMorphoV1Proofs(
        address[] memory urd,
        bytes[] memory txData
    ) internal pure returns (bytes memory proofs) {
        return MorphoV1Helper.encodeMorphoV1Proofs(urd, txData);
    }
}
