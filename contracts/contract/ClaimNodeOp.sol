// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./Base.sol";
import {MinipoolManager} from "./MinipoolManager.sol";
import {ProtocolDAO} from "./ProtocolDAO.sol";
import {RewardsPool} from "./RewardsPool.sol";
import {Staking} from "./Staking.sol";
import {Storage} from "./Storage.sol";
import {TokenGGP} from "./tokens/TokenGGP.sol";
import {Vault} from "./Vault.sol";

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

/// @title Node Operators claiming GGP Rewards
contract ClaimNodeOp is Base {
	using FixedPointMathLib for uint256;

	error InvalidAmount();
	error NoRewardsToClaim();
	error RewardsAlreadyDistributedToStaker(address);
	error RewardsCycleNotStarted();

	event GGPRewardsClaimed(address indexed to, uint256 amount);

	ERC20 public immutable ggp;

	constructor(Storage storageAddress, ERC20 ggp_) Base(storageAddress) {
		version = 1;
		ggp = ggp_;
	}

	/// @notice Get the total rewards for the most recent cycle
	function getRewardsCycleTotal() public view returns (uint256) {
		return getUint(keccak256("NOPClaim.RewardsCycleTotal"));
	}

	/// @dev Sets the total rewards for the most recent cycle
	function setRewardsCycleTotal(uint256 amount) public onlySpecificRegisteredContract("RewardsPool", msg.sender) {
		setUint(keccak256("NOPClaim.RewardsCycleTotal"), amount);
	}

	/// @notice Determines if a staker is eligible for the upcoming rewards cycle
	/// @dev Eligiblity: time in protocol (secs) > RewardsEligibilityMinSeconds. Rialto will call this.
	function isEligible(address stakerAddr) external view returns (bool) {
		Staking staking = Staking(getContractAddress("Staking"));
		uint256 rewardsStartTime = staking.getRewardsStartTime(stakerAddr);
		uint256 elapsedSecs = (block.timestamp - rewardsStartTime);
		ProtocolDAO dao = ProtocolDAO(getContractAddress("ProtocolDAO"));
		return (rewardsStartTime != 0 && elapsedSecs >= dao.getRewardsEligibilityMinSeconds());
	}

	/// @notice Set the share of rewards for a staker as a fraction of 1 ether
	/// @dev Rialto will call this
	function calculateAndDistributeRewards(address stakerAddr, uint256 totalEligibleGGPStaked) external onlyMultisig {
		Staking staking = Staking(getContractAddress("Staking"));
		staking.requireValidStaker(stakerAddr);

		RewardsPool rewardsPool = RewardsPool(getContractAddress("RewardsPool"));
		if (rewardsPool.getRewardsCycleCount() == 0) {
			revert RewardsCycleNotStarted();
		}

		if (staking.getLastRewardsCycleCompleted(stakerAddr) == rewardsPool.getRewardsCycleCount()) {
			revert RewardsAlreadyDistributedToStaker(stakerAddr);
		}
		staking.setLastRewardsCycleCompleted(stakerAddr, rewardsPool.getRewardsCycleCount());
		uint256 ggpEffectiveStaked = staking.getEffectiveGGPStaked(stakerAddr);
		uint256 percentage = ggpEffectiveStaked.divWadDown(totalEligibleGGPStaked);
		uint256 rewardsCycleTotal = getRewardsCycleTotal();
		uint256 rewardsAmt = percentage.mulWadDown(rewardsCycleTotal);
		if (rewardsAmt > rewardsCycleTotal) {
			revert InvalidAmount();
		}

		staking.resetAVAXAssignedHighWater(stakerAddr);
		staking.increaseGGPRewards(stakerAddr, rewardsAmt);

		// check if their rewards time should be reset
		uint256 minipoolCount = staking.getMinipoolCount(stakerAddr);
		if (minipoolCount == 0) {
			staking.setRewardsStartTime(stakerAddr, 0);
		}
	}

	/// @notice Claim GGP and automatically restake the remaining unclaimed rewards
	/// @param claimAmt The amount of GGP the staker would like to withdraw from the protocol
	function claimAndRestake(uint256 claimAmt) external {
		Staking staking = Staking(getContractAddress("Staking"));
		uint256 ggpRewards = staking.getGGPRewards(msg.sender);
		if (ggpRewards == 0) {
			revert NoRewardsToClaim();
		}
		if (claimAmt > ggpRewards) {
			revert InvalidAmount();
		}

		staking.decreaseGGPRewards(msg.sender, ggpRewards);

		Vault vault = Vault(getContractAddress("Vault"));
		uint256 restakeAmt = ggpRewards - claimAmt;
		if (restakeAmt > 0) {
			vault.withdrawToken(address(this), ggp, restakeAmt);
			ggp.approve(address(staking), restakeAmt);
			staking.restakeGGP(msg.sender, restakeAmt);
		}

		if (claimAmt > 0) {
			vault.withdrawToken(msg.sender, ggp, claimAmt);
		}

		emit GGPRewardsClaimed(msg.sender, claimAmt);
	}
}
