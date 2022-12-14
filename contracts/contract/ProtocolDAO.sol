// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./Base.sol";
import {TokenGGP} from "./tokens/TokenGGP.sol";
import {Storage} from "./Storage.sol";

/// @title Settings for the Protocol
contract ProtocolDAO is Base {
	error ValueNotWithinRange();

	modifier valueNotGreaterThanOne(uint256 setterValue) {
		if (setterValue > 1 ether) {
			revert ValueNotWithinRange();
		}
		_;
	}

	constructor(Storage storageAddress) Base(storageAddress) {
		version = 1;
	}

	function initialize() external onlyGuardian {
		if (getBool(keccak256("ProtocolDAO.initialized"))) {
			return;
		}
		setBool(keccak256("ProtocolDAO.initialized"), true);

		// ClaimNodeOp
		setUint(keccak256("ProtocolDAO.RewardsEligibilityMinSeconds"), 14 days);

		// RewardsPool
		setUint(keccak256("ProtocolDAO.RewardsCycleSeconds"), 28 days); // The time in which a claim period will span in seconds - 28 days by default
		setUint(keccak256("ProtocolDAO.TotalGGPCirculatingSupply"), 18_000_000 ether);
		setUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimMultisig"), 0.20 ether);
		setUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimNodeOp"), 0.70 ether);
		setUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimProtocolDAO"), 0.10 ether);

		// GGP Inflation
		setUint(keccak256("ProtocolDAO.InflationIntervalSeconds"), 1 days);
		setUint(keccak256("ProtocolDAO.InflationIntervalRate"), 1000133680617113500); // 5% annual calculated on a daily interval - Calculate in js example: let dailyInflation = web3.utils.toBN((1 + 0.05) ** (1 / (365)) * 1e18);

		// TokenGGAVAX
		setUint(keccak256("ProtocolDAO.TargetGGAVAXReserveRate"), 0.1 ether); // 10% collateral held in reserve

		// Minipool
		setUint(keccak256("ProtocolDAO.MinipoolMinAVAXStakingAmt"), 2_000 ether);
		setUint(keccak256("ProtocolDAO.MinipoolNodeCommissionFeePct"), 0.15 ether);
		setUint(keccak256("ProtocolDAO.MinipoolMaxAVAXAssignment"), 10_000 ether);
		setUint(keccak256("ProtocolDAO.MinipoolMinAVAXAssignment"), 1_000 ether);
		setUint(keccak256("ProtocolDAO.ExpectedAVAXRewardsRate"), 0.1 ether); // Annual rate as pct of 1 avax
		setUint(keccak256("ProtocolDAO.MinipoolCancelMoratoriumSeconds"), 5 days);

		// Staking
		setUint(keccak256("ProtocolDAO.MaxCollateralizationRatio"), 1.5 ether);
		setUint(keccak256("ProtocolDAO.MinCollateralizationRatio"), 0.1 ether);
	}

	/// @notice Get if a contract is paused
	/// @param contractName The contract that is being checked
	function getContractPaused(string memory contractName) public view returns (bool) {
		return getBool(keccak256(abi.encodePacked("contract.paused", contractName)));
	}

	/// @notice Pause a contract
	/// @param contractName The contract whose actions should be paused
	function pauseContract(string memory contractName) public onlySpecificRegisteredContract("Ocyticus", msg.sender) {
		setBool(keccak256(abi.encodePacked("contract.paused", contractName)), true);
	}

	/// @notice Unpause a contract
	/// @param contractName The contract whose actions should be resumed
	function resumeContract(string memory contractName) public onlySpecificRegisteredContract("Ocyticus", msg.sender) {
		setBool(keccak256(abi.encodePacked("contract.paused", contractName)), false);
	}

	// *** Rewards Pool ***

	/// @notice Get how many seconds a node must be registered for rewards to be eligible for the rewards cycle
	/// @return uint256 The min number of seconds to be considered eligible
	function getRewardsEligibilityMinSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.RewardsEligibilityMinSeconds"));
	}

	/// @notice Get how many seconds in a rewards cycle
	function getRewardsCycleSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.RewardsCycleSeconds"));
	}

	/// @notice The total amount of GGP that is in circulation
	function getTotalGGPCirculatingSupply() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.TotalGGPCirculatingSupply"));
	}

	/// @notice Set the amount of GGP that is in circulation
	function setTotalGGPCirculatingSupply(uint256 amount) public onlySpecificRegisteredContract("RewardsPool", msg.sender) {
		return setUint(keccak256("ProtocolDAO.TotalGGPCirculatingSupply"), amount);
	}

	/// @notice The percentage a contract is owed for a rewards cycle
	/// @return uint256 Rewards percentage a contract will receive this cycle
	function getClaimingContractPct(string memory claimingContract) public view returns (uint256) {
		return getUint(keccak256(abi.encodePacked("ProtocolDAO.ClaimingContractPct.", claimingContract)));
	}

	/// @notice Set the percentage a contract is owed for a rewards cycle
	function setClaimingContractPct(string memory claimingContract, uint256 decimal) public onlyGuardian valueNotGreaterThanOne(decimal) {
		setUint(keccak256(abi.encodePacked("ProtocolDAO.ClaimingContractPct.", claimingContract)), decimal);
	}

	// *** GGP Inflation ***

	/// @notice The current inflation rate per interval (eg 1000133680617113500 = 5% annual)
	/// @return uint256 The current inflation rate per interval (can never be < 1 ether)
	function getInflationIntervalRate() external view returns (uint256) {
		// Inflation rate controlled by the DAO
		uint256 rate = getUint(keccak256("ProtocolDAO.InflationIntervalRate"));
		return rate < 1 ether ? 1 ether : rate;
	}

	/// @notice How many seconds to calculate inflation at
	/// @return uint256 how many seconds to calculate inflation at
	function getInflationIntervalSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.InflationIntervalSeconds"));
	}

	// *** Minipool Settings ***

	/// @notice The min AVAX staking amount that is required for creating a minipool
	function getMinipoolMinAVAXStakingAmt() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMinAVAXStakingAmt"));
	}

	/// @notice The node commision fee for running the hardware for the minipool
	function getMinipoolNodeCommissionFeePct() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolNodeCommissionFeePct"));
	}

	/// @notice Maximum AVAX a Node Operator can be assigned from liquid staking funds
	function getMinipoolMaxAVAXAssignment() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMaxAVAXAssignment"));
	}

	/// @notice Minimum AVAX a Node Operator can be assigned from liquid staking funds
	function getMinipoolMinAVAXAssignment() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMinAVAXAssignment"));
	}

	/// @notice The user must wait this amount of time before they can cancel their minipool
	function getMinipoolCancelMoratoriumSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolCancelMoratoriumSeconds"));
	}

	/// @notice Set the rewards rate for validating Avalanche's p-chain
	/// @dev Used for testing
	function setExpectedAVAXRewardsRate(uint256 rate) public onlyMultisig valueNotGreaterThanOne(rate) {
		setUint(keccak256("ProtocolDAO.ExpectedAVAXRewardsRate"), rate);
	}

	/// @notice The expected rewards rate for validating Avalanche's P-chain
	function getExpectedAVAXRewardsRate() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.ExpectedAVAXRewardsRate"));
	}

	//*** Staking ***

	/// @notice The max collateralization ratio of GGP to Assigned AVAX eligible for rewards
	function getMaxCollateralizationRatio() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MaxCollateralizationRatio"));
	}

	/// @notice The min collateralization ratio of GGP to Assigned AVAX eligible for rewards or minipool creation
	function getMinCollateralizationRatio() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinCollateralizationRatio"));
	}

	/// @notice The target percentage of ggAVAX to hold in TokenggAVAX contract
	/// 	1 ether = 100%
	/// 	0.1 ether = 10%
	/// @return uint256 The current target reserve rate
	function getTargetGGAVAXReserveRate() external view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.TargetGGAVAXReserveRate"));
	}

	//*** Contract Registration ***

	/// @notice Register a new contract with Storage
	/// @param addr Contract address to register
	/// @param name Contract name to register
	function registerContract(address addr, string memory name) public onlyGuardian {
		setBool(keccak256(abi.encodePacked("contract.exists", addr)), true);
		setAddress(keccak256(abi.encodePacked("contract.address", name)), addr);
		setString(keccak256(abi.encodePacked("contract.name", addr)), name);
	}

	/// @notice Unregister a contract with Storage
	/// @param addr Contract address to unregister
	function unregisterContract(address addr) public onlyGuardian {
		string memory name = getContractName(addr);
		deleteBool(keccak256(abi.encodePacked("contract.exists", addr)));
		deleteAddress(keccak256(abi.encodePacked("contract.address", name)));
		deleteString(keccak256(abi.encodePacked("contract.name", addr)));
	}

	/// @notice Upgrade a contract by unregistering the existing address, and registring a new address and name
	/// @param newAddr Address of the new contract
	/// @param newName Name of the new contract
	/// @param existingAddr Address of the existing contract to be deleted
	function upgradeExistingContract(
		address newAddr,
		string memory newName,
		address existingAddr
	) external onlyGuardian {
		registerContract(newAddr, newName);
		unregisterContract(existingAddr);
	}
}
