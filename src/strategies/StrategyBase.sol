//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {ERC4626Upgradeable, IERC20, IERC20Metadata, IERC4626} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Errors} from "../interfaces/Errors.sol";
import {ReturnedRewards} from "../interfaces/IStrategy.sol";
import {IStrategy, ReturnedRewards} from "../interfaces/IStrategy.sol";

import {TokenHelper} from "@blueprint-finance/hub-and-spokes-libraries/src/libraries/TokenHelper.sol";

struct RewardToken {
    IERC20 token;
    uint256 fee;
    uint256 accumulatedFeeAccounted;
}

abstract contract StrategyBase is
    IERC4626,
    IStrategy,
    ERC4626Upgradeable,
    ReentrancyGuard,
    OwnableUpgradeable,
    Errors,
    PausableUpgradeable
{
    using Math for uint256;
    using SafeERC20 for IERC20;

    address internal _vault;

    // Array to store the reward tokens associated with the strategy
    RewardToken[] public rewardTokens;
    // Address where fees collected by the strategy are sent
    address public feeRecipient;
    // Maximum amount of the base asset that can be deposited into the strategy
    uint256 public depositLimit;
    // Number of decimals the strategy's shares will have, derived from the base asset's decimals
    //slither-disable-next-line naming-convention
    uint8 public _decimals;
    // Offset to adjust the decimals of the strategy's shares
    uint8 public constant DECIMAL_OFFSET = 9;

    // Mapping to track which reward tokens have been approved for use in the strategy
    mapping(address => bool) public rewardTokenApproved;

    event Harvested(address indexed harvester, uint256 tvl);

    modifier onlyVault() {
        if (msg.sender != _vault) revert OnlyVault(msg.sender);
        _;
    }

    /**
     * @dev Initializes the StrategyBase contract with necessary parameters and setups.
     * This includes initializing inherited contracts, setting up reward tokens, fee recipient, deposit limit, and share decimals.
     * @param baseAsset_ The base asset of the strategy.
     * @param shareName_ The name of the strategy's share token.
     * @param shareSymbol_ The symbol of the strategy's share token.
     * @param feeRecipient_ The address where collected fees will be sent.
     * @param depositLimit_ The maximum amount of the base asset that can be deposited.
     * @param owner_ The owner of the strategy.
     * @param rewardTokens_ An array of reward tokens associated with the strategy.
     */
    // slither didn't detect the nonReentrant modifier
    // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,naming-convention
    function __StrategyBase_init(
        IERC20 baseAsset_,
        string memory shareName_,
        string memory shareSymbol_,
        address feeRecipient_,
        uint256 depositLimit_,
        address owner_,
        RewardToken[] memory rewardTokens_,
        address vault_
    ) internal initializer nonReentrant {
        // Initialize inherited contracts
        __ERC4626_init(IERC20Metadata(address(baseAsset_)));
        __ERC20_init(shareName_, shareSymbol_);
        __Ownable_init(owner_);

        // Iterate through the provided reward tokens to set them up
        if (rewardTokens_.length != 0) {
            for (uint256 i; i < rewardTokens_.length; ) {
                // Validate reward token address, current fee accounted, and high watermark
                if (address(rewardTokens_[i].token) == address(0)) {
                    revert InvalidRewardTokenAddress();
                }
                if (rewardTokens_[i].accumulatedFeeAccounted != 0) {
                    revert AccumulatedFeeAccountedMustBeZero();
                }

                // Approve the strategy to spend the reward token without limit
                if (!rewardTokens_[i].token.approve(address(this), type(uint256).max)) revert ERC20ApproveFail();
                // Add the reward token to the strategy's list and mark it as approved
                rewardTokens.push(rewardTokens_[i]);
                rewardTokenApproved[address(rewardTokens_[i].token)] = true;
                unchecked {
                    i++;
                }
            }
        }

        // Validate and set the fee recipient address
        if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();
        feeRecipient = feeRecipient_;

        // Set the deposit limit for the strategy
        if (depositLimit_ == 0) revert InvalidDepositLimit();

        depositLimit = depositLimit_;
        // Calculate and set the decimals for the strategy's shares based on the base asset's decimals
        _decimals = IERC20Metadata(address(baseAsset_)).decimals() + DECIMAL_OFFSET;
        _vault = vault_;
    }

    /**
     * @dev Internal function to deposit assets into the strategy.
     * @param caller_ The address initiating the deposit.
     * @param receiver_ The address receiving the deposited shares.
     * @param assets_ The amount of assets to deposit.
     * @param shares_ The amount of shares to mint.
     */
    function _deposit(
        address caller_,
        address receiver_,
        uint256 assets_,
        uint256 shares_
    ) internal virtual override(ERC4626Upgradeable) whenNotPaused onlyVault {
        //slither-disable-next-line incorrect-equality
        if (shares_ == 0 || assets_ == 0) revert ZeroAmount();
        IERC20(asset()).safeTransferFrom(caller_, address(this), assets_);

        _protocolDeposit(assets_, shares_);

        _mint(receiver_, shares_);

        emit Deposit(caller_, receiver_, assets_, shares_);
    }

    /**
     * @dev Internal function to withdraw assets from the strategy.
     * @param caller_ The address initiating the withdrawal.
     * @param receiver_ The address receiving the withdrawn assets.
     * @param owner_ The owner of the strategy.
     * @param assets_ The amount of assets to withdraw.
     * @param shares_ The amount of shares to burn.
     */
    //It can only be called by the vault
    //slither-disable-next-line reentrancy-events
    function _withdraw(
        address caller_,
        address receiver_,
        address owner_,
        uint256 assets_,
        uint256 shares_
    ) internal virtual override(ERC4626Upgradeable) whenNotPaused onlyVault {
        //slither-disable-next-line incorrect-equality
        if (shares_ == 0 || assets_ == 0) revert ZeroAmount();

        _protocolWithdraw(assets_, shares_);

        _burn(owner_, shares_);
        _handleRewardsOnWithdraw();
        IERC20(asset()).safeTransfer(receiver_, assets_);

        emit Withdraw(caller_, receiver_, owner_, assets_, shares_);
    }

    /**
     * @dev Public function to get the total assets held by the strategy.
     * @return The total assets held by the strategy.
     */
    function totalAssets() public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        // use the balance of this address + allow for custom totalAssets logic inside the strategy
        // This is because some strategies will just have funds inside them, and others will have funds in third parties.
        // The strategies with funds in third parties will need to show the actual balance, taking that into account
        return IERC20(asset()).balanceOf(address(this)) + _totalAssets();
    }

    /**
     * @notice Adds a new reward token to the strategy.
     * @dev This function allows the owner to add a new reward token to the strategy's list of reward tokens.
     * It checks for several conditions to ensure the integrity of the reward token being added.
     * @param rewardToken_ The reward token to be added, encapsulated in a RewardToken struct.
     */
    function addRewardToken(RewardToken calldata rewardToken_) external onlyOwner nonReentrant {
        // Ensure the reward token address is not zero, not already approved, and its parameters are correctly initialized.
        if (address(rewardToken_.token) == address(0)) {
            revert InvalidRewardTokenAddress();
        }
        if (rewardTokenApproved[address(rewardToken_.token)]) {
            revert RewardTokenAlreadyApproved();
        }
        if (rewardToken_.accumulatedFeeAccounted != 0) {
            revert AccumulatedFeeAccountedMustBeZero();
        }

        // Add the reward token to the list and approve it for unlimited spending by the strategy.
        rewardTokens.push(rewardToken_);
        rewardTokenApproved[address(rewardToken_.token)] = true;
        if (!rewardToken_.token.approve(address(this), type(uint256).max)) {
            revert ERC20ApproveFail();
        }
    }

    /**
     * @notice Removes a reward token from the strategy.
     * @dev This function allows the owner to remove a reward token from the strategy's list of reward tokens.
     * It shifts the elements in the array to maintain a compact array after removal.
     * @param rewardToken_ The reward token to be removed, encapsulated in a RewardToken struct.
     */
    function removeRewardToken(RewardToken calldata rewardToken_) external onlyOwner {
        // Ensure the reward token is approved before attempting removal.
        if (!rewardTokenApproved[address(rewardToken_.token)]) {
            revert RewardTokenNotApproved();
        }

        rewardTokens[_getIndex(address(rewardToken_.token))] = rewardTokens[rewardTokens.length - 1];
        rewardTokens.pop();

        // Mark the reward token as not approved.
        rewardTokenApproved[address(rewardToken_.token)] = false;
    }

    /**
     * @notice Modifies the fee associated with a reward token.
     * @dev This function allows the owner to modify the fee percentage for a specific reward token.
     * @param newFee_ The new fee percentage to be applied.
     * @param rewardToken_ The reward token whose fee is being modified, encapsulated in a RewardToken struct.
     */
    function modifyRewardFeeForRewardToken(uint256 newFee_, RewardToken calldata rewardToken_) external onlyOwner {
        // Ensure the reward token is approved before attempting to modify its fee.
        if (!rewardTokenApproved[address(rewardToken_.token)]) {
            revert RewardTokenNotApproved();
        }

        // Find the index of the reward token to modify.
        uint256 index = _getIndex(address(rewardToken_.token));

        // Update the fee for the specified reward token.
        rewardTokens[index].fee = newFee_;
    }

    /**
     * @notice Handles the distribution of accrued rewards upon withdrawal.
     * @dev This function is called during a withdrawal operation to distribute any accrued rewards to the withdrawing vault.
     * It first accrues user rewards, then iterates through all reward tokens to distribute the accrued rewards.
     */
    function _handleRewardsOnWithdraw() internal virtual;

    /**
     * @notice Sets the recipient address for protocol fees.
     * @dev Can only be called by the contract owner.
     * @param feeRecipient_ The address to which protocol fees will be sent.
     */
    function setFeeRecipient(address feeRecipient_) external onlyOwner {
        if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();
        feeRecipient = feeRecipient_;
    }

    /**
     * @notice Sets the maximum limit for deposits into the strategy.
     * @dev Can only be called by the contract owner.
     * @param depositLimit_ The maximum amount that can be deposited.
     */
    //TODO: Add events for these functions
    //slither-disable-next-line events-maths
    function setDepositLimit(uint256 depositLimit_) external onlyOwner {
        if (depositLimit_ == 0) revert InvalidDepositLimit();
        depositLimit = depositLimit_;
    }

    // VIEWS

    /**
     * @notice Retrieves the user's accrued rewards for a specific token.
     * @dev Accrues rewards for the user before returning the reward balance.
     * @param user_ The address of the user whose rewards are being queried.
     * @param token_ The address of the token for which rewards are being queried.
     * @return UserRewardBalance The accrued rewards for the user for the specified token.
     */

    /**
     * @notice Returns the list of reward tokens configured in the strategy.
     * @dev Provides a view function to retrieve all reward tokens.
     * @return RewardToken[] An array of reward token configurations.
     */
    function getRewardTokens() external view returns (RewardToken[] memory) {
        return rewardTokens; // Return the array of configured reward tokens.
    }

    // Internal

    /**
     * @notice Finds the index of a given token in the reward tokens array.
     * @dev Iterates through the reward tokens array to find the index of the specified token.
     * @param token_ The address of the token to find.
     * @return index The index of the token in the reward tokens array, if found.
     */
    function _getIndex(address token_) internal view returns (uint256 index) {
        uint256 len = rewardTokens.length;
        for (uint256 i; i < len; ) {
            if (address(rewardTokens[i].token) == token_) {
                index = i; // Set the index if the token is found.
                break; // Exit the loop once the token is found.
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Generates an array of RewardToken structs for the strategy.
     * @param rewardFee_ The fee percentage for the reward tokens.
     * @return An array of RewardToken structs.
     */
    function _getRewardTokens(uint256 rewardFee_) internal view returns (RewardToken[] memory) {
        address[] memory rewards = getRewardTokenAddresses();
        RewardToken[] memory r = new RewardToken[](rewards.length);
        for (uint256 i = 0; i < rewards.length; ) {
            r[i] = RewardToken({token: IERC20(rewards[i]), fee: rewardFee_, accumulatedFeeAccounted: 0});
            unchecked {
                ++i;
            }
        }
        return r;
    }

    //no reentrancy possible since the only one able to call this function is the vault
    //slither-disable-next-line reentrancy-no-eth,reentrancy-events
    function harvestRewards(
        bytes memory data
    ) public virtual override(IStrategy) onlyVault returns (ReturnedRewards[] memory) {
        _getRewardsToStrategy(data);
        uint256 len = rewardTokens.length;
        ReturnedRewards[] memory returnedRewards = new ReturnedRewards[](len);
        for (uint256 i = 0; i < len; ) {
            IERC20 rewardAddress = rewardTokens[i].token;

            uint256 netReward = 0;
            uint256 claimedBalance = rewardAddress.balanceOf(address(this));
            if (claimedBalance != 0) {
                uint256 collectedFee = claimedBalance.mulDiv(rewardTokens[i].fee, 10000, Math.Rounding.Ceil);

                if (TokenHelper.attemptSafeTransfer(address(rewardAddress), feeRecipient, collectedFee, false)) {
                    rewardTokens[i].accumulatedFeeAccounted += collectedFee;
                    netReward = claimedBalance - collectedFee;
                    emit Harvested(_vault, netReward);
                }

                // rewardAddress.safeTransfer(_vault, netReward);
                TokenHelper.attemptSafeTransfer(address(rewardAddress), _vault, netReward, false);
            }

            returnedRewards[i] = ReturnedRewards(address(rewardAddress), netReward);
            unchecked {
                ++i;
            }
        }
        return returnedRewards;
    }

    function getRewardTokenAddresses() public view virtual returns (address[] memory) {
        uint256 len = rewardTokens.length;
        address[] memory rT = new address[](len);
        for (uint256 i = 0; i < len; ) {
            rT[i] = address(rewardTokens[i].token);
            unchecked {
                ++i;
            }
        }
        return rT;
    }

    function _protocolDeposit(uint256 assets, uint256 shares) internal virtual {}
    function _protocolWithdraw(uint256 assets, uint256 shares) internal virtual {}
    function _totalAssets() internal view virtual returns (uint256);
    function _getRewardsToStrategy(bytes memory data) internal virtual;
}
