// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./utils/BaseTest.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

contract RewardsPoolTest is BaseTest {
	using FixedPointMathLib for uint256;

	uint256 private constant TOTAL_INITIAL_SUPPLY = 22500000 ether;

	function setUp() public override {
		super.setUp();
		distributeInitialSupply();
	}

	function distributeInitialSupply() public {
		// note: guardian is minted 100% of the supply
		vm.startPrank(guardian);

		uint256 companyAllocation = TOTAL_INITIAL_SUPPLY.mulWadDown(.32 ether);
		uint256 pDaoAllo = TOTAL_INITIAL_SUPPLY.mulWadDown(.3233 ether);
		uint256 seedInvestorAllo = TOTAL_INITIAL_SUPPLY.mulWadDown(.1567 ether);
		uint256 rewardsPoolAllo = TOTAL_INITIAL_SUPPLY.mulWadDown(.20 ether); //4.5 million

		// approve vault deposits for all tokens that won't be in company wallet
		ggp.approve(address(vault), TOTAL_INITIAL_SUPPLY - companyAllocation);

		// 33% to the pDAO wallet
		vault.depositToken("ProtocolDAO", ggp, pDaoAllo);

		// TODO make an actual vesting contract
		// 15.67% to vesting smart contract
		vault.depositToken("ProtocolDAO", ggp, seedInvestorAllo);

		// 20% to staking rewards contract
		vault.depositToken("RewardsPool", ggp, rewardsPoolAllo);

		vm.stopPrank();
	}

	function testInitialization() public {
		assertTrue(store.getBool(keccak256("RewardsPool.initialized")));
		assertGt(rewardsPool.getInflationIntervalStartTime(), 0);
		assertGt(rewardsPool.getRewardsCycleStartTime(), 0);
	}

	function testGetInflationIntervalsElapsed() public {
		assertEq(rewardsPool.getInflationIntervalsElapsed(), 0);
		skip(dao.getInflationIntervalSeconds());
		assertEq(rewardsPool.getInflationIntervalsElapsed(), 1);
	}

	//TODO test this full 5 years
	function testInflationCalculate() public {
		uint256 curSupply;
		uint256 newSupply;

		// Hard-code numbers for this specific test
		uint256 totalCirculatingSupply = 18000000 ether;
		store.setUint(keccak256("ProtocolDAO.TotalGGPCirculatingSupply"), totalCirculatingSupply);
		assertEq(dao.getTotalGGPCirculatingSupply(), totalCirculatingSupply);

		uint256 inflationRate = 1000133680617113500;
		store.setUint(keccak256("ProtocolDAO.InflationIntervalRate"), inflationRate);
		assertEq(dao.getInflationIntervalRate(), inflationRate);

		(curSupply, newSupply) = rewardsPool.getInflationAmt();
		assertEq(curSupply, totalCirculatingSupply);
		// No inflation expected
		assertEq(newSupply, totalCirculatingSupply);

		skip(dao.getInflationIntervalSeconds());

		//1 cycle, should be 2406.06
		(curSupply, newSupply) = rewardsPool.getInflationAmt();
		assertEq(newSupply - curSupply, 2406251108043000000000);

		//this happens in inflate()
		store.setUint(keccak256("ProtocolDAO.TotalGGPCirculatingSupply"), totalCirculatingSupply + 2406251108043000000000);

		//2 cycles
		skip(dao.getInflationIntervalSeconds());

		(curSupply, newSupply) = rewardsPool.getInflationAmt();
		assertEq(newSupply - curSupply, 4813467266486087907130);

		skip(1676 days); // ~4.6 years
		(curSupply, newSupply) = rewardsPool.getInflationAmt();
		// we have 4.5 mil ether to give out. So the rewards cycle will be
		assertEq(newSupply - curSupply, 4526664600019446164419790);
	}

	function testMaxInflation() public {
		// skip 54 months ahead and start rewards cycle
		skip(142006867);
		rewardsPool.startRewardsCycle();
		uint256 tcs = dao.getTotalGGPCirculatingSupply();
		assertLt(tcs, 22_500_000 ether);

		// one more month inflates more than 22.5 million tokens
		skip(2629756);
		vm.expectRevert(RewardsPool.MaximumTokensReached.selector);
		rewardsPool.startRewardsCycle();
	}

	function testGetClaimingContractDistribution() public {
		assert(rewardsPool.getClaimingContractDistribution("ClaimProtocolDAO") == 0);
		assert(rewardsPool.getClaimingContractDistribution("ClaimNodeOp") == 0);

		skip(dao.getRewardsCycleSeconds());

		rewardsPool.startRewardsCycle();
		uint256 rewardsTotal = rewardsPool.getRewardsCycleTotalAmt();

		uint256 protocolAllot = rewardsTotal.mulWadDown(dao.getClaimingContractPct("ClaimProtocolDAO"));
		assert(rewardsPool.getClaimingContractDistribution("ClaimProtocolDAO") == protocolAllot);

		uint256 nopAllot = rewardsTotal.mulWadDown(dao.getClaimingContractPct("ClaimNodeOp"));
		assert(rewardsPool.getClaimingContractDistribution("ClaimNodeOp") == nopAllot);
	}

	function testStartRewardsCycle() public {
		uint256 rewardsCycleStartTime = rewardsPool.getRewardsCycleStartTime();

		vm.expectRevert(RewardsPool.UnableToStartRewardsCycle.selector);
		rewardsPool.startRewardsCycle();
		assertFalse(rewardsPool.canStartRewardsCycle());
		assertEq(vault.balanceOfToken("ClaimNodeOp", ggp), 0);
		assertEq(vault.balanceOfToken("ClaimProtocolDAO", ggp), 0);
		assertEq(store.getUint(keccak256("RewardsPool.RewardsCycleTotalAmt")), 0);
		assertEq(rewardsPool.getRewardsCycleCount(), 0);

		skip(dao.getRewardsCycleSeconds());

		assertEq(rewardsPool.getRewardsCyclesElapsed(), 1);
		assertTrue(rewardsPool.canStartRewardsCycle());

		rewardsPool.startRewardsCycle();

		uint256 rewardsCycleTotal = rewardsPool.getRewardsCycleTotalAmt();
		uint256 claimProtocolPerc = store.getUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimProtocolDAO"));
		uint256 claimNodeOpPerc = store.getUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimNodeOp"));
		uint256 multisigPerc = store.getUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimMultisig"));

		assertEq(rewardsPool.getRewardsCycleStartTime(), rewardsCycleStartTime + dao.getRewardsCycleSeconds());
		assertGt(rewardsCycleTotal, 0);
		assertEq(vault.balanceOfToken("ClaimNodeOp", ggp), rewardsCycleTotal.mulWadDown(claimNodeOpPerc));
		assertEq(vault.balanceOfToken("ClaimProtocolDAO", ggp), rewardsCycleTotal.mulWadDown(claimProtocolPerc));
		assertEq(ggp.balanceOf(address(rialto)), rewardsCycleTotal.mulWadDown(multisigPerc));

		assertEq(rewardsPool.getRewardsCycleCount(), 1);
	}

	function testMulitpleMultisigRewards() public {
		// create three enabled multisigs (rialto, multisig1, multisig2)
		// and one disabled (multisig3)
		address multisig1 = getActor("multisig1");
		address multisig2 = getActor("multisig2");
		address multisig3 = getActor("multisig3");

		vm.startPrank(guardian);
		multisigMgr.registerMultisig(multisig1);
		multisigMgr.registerMultisig(multisig2);
		multisigMgr.registerMultisig(multisig3);

		multisigMgr.enableMultisig(multisig1);
		multisigMgr.enableMultisig(multisig2);
		vm.stopPrank();

		skip(dao.getRewardsCycleSeconds());
		assertEq(rewardsPool.getRewardsCyclesElapsed(), 1);
		assertTrue(rewardsPool.canStartRewardsCycle());

		startMeasuringGas("testGasCreateMinipool");
		rewardsPool.startRewardsCycle();
		stopMeasuringGas();

		uint256 rewardsCycleTotal = rewardsPool.getRewardsCycleTotalAmt();
		uint256 multisigPerc = store.getUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimMultisig"));
		uint256 amtPerMultisig = rewardsCycleTotal.mulWadDown(multisigPerc) / 3;

		assertEq(ggp.balanceOf(address(rialto)), amtPerMultisig);
		assertEq(ggp.balanceOf(multisig1), amtPerMultisig);
		assertEq(ggp.balanceOf(multisig2), amtPerMultisig);
		assertEq(ggp.balanceOf(multisig3), 0);
	}
}
