// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./utils/BaseTest.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

contract MinipoolManagerTest is BaseTest {
	using FixedPointMathLib for uint256;
	int256 private index;
	address private nodeOp;
	uint256 private status;
	uint256 private ggpBondAmt;

	function setUp() public override {
		super.setUp();
		nodeOp = getActorWithTokens("nodeOp", MAX_AMT, MAX_AMT);
	}

	function testGetTotalAVAXLiquidStakerAmt() public {
		address nodeOp2 = getActorWithTokens("nodeOp", MAX_AMT, MAX_AMT);
		address liqStaker1 = getActorWithTokens("liqStaker1", 4000 ether, 0);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: 4000 ether}();

		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 0);

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(200 ether);
		MinipoolManager.Minipool memory mp1 = createMinipool(1000 ether, 1000 ether, 2 weeks);
		vm.stopPrank();
		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);
		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 1000 ether);

		vm.prank(nodeOp);
		MinipoolManager.Minipool memory mp2 = createMinipool(1000 ether, 1000 ether, 2 weeks);
		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp2.nodeID);
		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 2000 ether);

		vm.startPrank(nodeOp2);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(100 ether);
		MinipoolManager.Minipool memory mp3 = createMinipool(1000 ether, 1000 ether, 2 weeks);
		vm.stopPrank();
		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp3.nodeID);
		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 3000 ether);
	}

	function testCreateMinipool() public {
		address nodeID = address(1);
		uint256 duration = 2 weeks;
		uint256 delegationFee = 20;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 nopAvaxAmount = 1000 ether;

		uint256 vaultOriginalBalance = vault.balanceOf("MinipoolManager");

		assertEq(minipoolMgr.getMinipoolCount(), 0);

		//fail
		vm.startPrank(nodeOp);
		vm.expectRevert(MinipoolManager.InvalidNodeID.selector);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(address(0), duration, delegationFee, avaxAssignmentRequest);

		//fail
		vm.expectRevert(MinipoolManager.InvalidAVAXAssignmentRequest.selector);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(nodeID, duration, delegationFee, 2000 ether);

		//fail
		vm.expectRevert(MinipoolManager.InvalidAVAXAssignmentRequest.selector);
		minipoolMgr.createMinipool{value: 2000 ether}(nodeID, duration, delegationFee, avaxAssignmentRequest);

		//fail
		vm.expectRevert(Staking.StakerNotFound.selector);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(nodeID, duration, delegationFee, avaxAssignmentRequest);

		//fail
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(50 ether);
		vm.expectRevert(MinipoolManager.InsufficientGGPCollateralization.selector);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(nodeID, duration, delegationFee, avaxAssignmentRequest);

		staking.stakeGGP(50 ether);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(nodeID, duration, delegationFee, avaxAssignmentRequest);

		//check vault balance to increase by 1000 ether
		assertEq(vault.balanceOf("MinipoolManager") - vaultOriginalBalance, nopAvaxAmount);

		int256 stakerIndex = staking.getIndexOf(address(nodeOp));
		Staking.Staker memory staker = staking.getStaker(stakerIndex);
		assertEq(staker.avaxStaked, avaxAssignmentRequest);
		assertEq(staker.avaxAssigned, nopAvaxAmount);
		assertEq(staker.minipoolCount, 1);
		assertTrue(staker.rewardsStartTime != 0);

		int256 minipoolIndex = minipoolMgr.getIndexOf(nodeID);
		MinipoolManager.Minipool memory mp = minipoolMgr.getMinipool(minipoolIndex);

		assertEq(mp.nodeID, nodeID);
		assertEq(mp.status, uint256(MinipoolStatus.Prelaunch));
		assertEq(mp.duration, duration);
		assertEq(mp.delegationFee, delegationFee);
		assertEq(mp.avaxLiquidStakerAmt, avaxAssignmentRequest);
		assertEq(mp.avaxNodeOpAmt, nopAvaxAmount);
		assertEq(mp.owner, address(nodeOp));

		//check that making the same minipool with this id will reset the minipool data
		skip(5 seconds); //cancellation moratorium
		minipoolMgr.cancelMinipool(nodeID);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(nodeID, 3 weeks, delegationFee, avaxAssignmentRequest);
		int256 minipoolIndex1 = minipoolMgr.getIndexOf(nodeID);
		MinipoolManager.Minipool memory mp1 = minipoolMgr.getMinipool(minipoolIndex1);
		assertEq(mp1.nodeID, nodeID);
		assertEq(mp1.status, uint256(MinipoolStatus.Prelaunch));
		assertEq(mp1.duration, 3 weeks);
		assertEq(mp1.delegationFee, delegationFee);
		assertEq(mp1.avaxLiquidStakerAmt, avaxAssignmentRequest);
		assertEq(mp1.avaxNodeOpAmt, nopAvaxAmount);
		assertEq(mp1.owner, address(nodeOp));
	}

	function testCancelMinipool() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		//will fail
		vm.expectRevert(MinipoolManager.MinipoolNotFound.selector);
		minipoolMgr.cancelMinipool(address(0));

		//will fail
		vm.expectRevert(MinipoolManager.OnlyOwner.selector);
		minipoolMgr.cancelMinipool(mp1.nodeID);

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Error));
		vm.prank(nodeOp);

		//will fail
		vm.expectRevert(MinipoolManager.CancellationTooEarly.selector);
		minipoolMgr.cancelMinipool(mp1.nodeID);

		skip(5 seconds); //cancellation moratorium

		vm.prank(nodeOp);
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.cancelMinipool(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Prelaunch));

		vm.startPrank(nodeOp);
		uint256 priorBalance = nodeOp.balance;
		minipoolMgr.cancelMinipool(mp1.nodeID);

		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);

		assertEq(mp1Updated.status, uint256(MinipoolStatus.Canceled));
		assertEq(staking.getMinipoolCount(mp1Updated.owner), 0);
		assertEq(staking.getAVAXStake(mp1Updated.owner), 0);
		assertEq(staking.getAVAXAssigned(mp1Updated.owner), 0);

		assertEq(nodeOp.balance - priorBalance, mp1Updated.avaxNodeOpAmt);
	}

	function testWithdrawMinipoolFunds() public {
		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		vm.startPrank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);
		bytes32 txID = keccak256("txid");
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);

		skip(duration);

		uint256 rewards = 10 ether;
		uint256 halfRewards = rewards / 2;
		deal(address(rialto), address(rialto).balance + rewards);
		minipoolMgr.recordStakingEnd{value: validationAmt + rewards}(mp1.nodeID, block.timestamp, rewards);
		uint256 percentage = dao.getMinipoolNodeCommissionFeePct();
		uint256 commissionFee = (percentage).mulWadDown(halfRewards);
		vm.stopPrank();

		vm.startPrank(nodeOp);
		uint256 priorBalanceNodeOp = nodeOp.balance;
		minipoolMgr.withdrawMinipoolFunds(mp1.nodeID);
		assertEq((nodeOp.balance - priorBalanceNodeOp), (1000 ether + halfRewards + commissionFee));
	}

	function testCanClaimAndInitiateStaking() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);

		//will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.canClaimAndInitiateStaking(mp1.nodeID);
		vm.stopPrank();

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Error));
		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.canClaimAndInitiateStaking(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Prelaunch));

		//will fail
		vm.prank(address(rialto));
		assertEq(minipoolMgr.canClaimAndInitiateStaking(mp1.nodeID), false);

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		vm.prank(address(rialto));
		assertEq(minipoolMgr.canClaimAndInitiateStaking(mp1.nodeID), true);
	}

	function testClaimAndInitiateStaking() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;
		uint256 originalRialtoBalance = address(rialto).balance;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);

		//will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);
		vm.stopPrank();

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Error));
		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Prelaunch));

		//will fail
		vm.prank(address(rialto));
		vm.expectRevert(TokenggAVAX.WithdrawAmountTooLarge.selector);
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		uint256 originalMMbalance = vault.balanceOf("MinipoolManager");

		uint256 originalGGAVAXBalance = ggAVAX.amountAvailableForStaking();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);
		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);
		assertEq(mp1Updated.status, uint256(MinipoolStatus.Launched));
		assertEq(address(rialto).balance - originalRialtoBalance, (depositAmt + avaxAssignmentRequest));
		assertEq(originalMMbalance - vault.balanceOf("MinipoolManager"), depositAmt);
		assertEq((originalGGAVAXBalance - ggAVAX.amountAvailableForStaking()), avaxAssignmentRequest);
	}

	function testRecordStakingStart() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);

		bytes32 txID = keccak256("txid");

		//will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Error));
		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Launched));

		vm.prank(address(rialto));
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);
		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);
		assertEq(mp1Updated.status, uint256(MinipoolStatus.Staking));
		assertEq(mp1Updated.txID, txID);
		assertTrue(mp1Updated.startTime != 0);
	}

	function testRecordStakingStartInvalidStartTime() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;
		uint256 liquidStakerAmt = 1200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), ggpStakeAmt);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		address liqStaker1 = getActorWithTokens("liqStaker1", uint128(liquidStakerAmt), 0);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: liquidStakerAmt}();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);

		bytes32 txID = keccak256("txid");

		vm.expectRevert(MinipoolManager.InvalidStartTime.selector);
		vm.prank(address(rialto));
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp + 1);
	}

	function testRecordStakingEnd() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);

		bytes32 txID = keccak256("txid");
		vm.prank(address(rialto));
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);

		//will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Error));
		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Staking));

		vm.startPrank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidEndTime.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);

		skip(duration);

		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingEnd{value: 0 ether}(mp1.nodeID, block.timestamp, 0 ether);

		// Give rialto the rewards it needs
		uint256 rewards = 10 ether;
		uint256 halfRewards = rewards / 2;
		deal(address(rialto), address(rialto).balance + rewards);

		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt + rewards}(mp1.nodeID, block.timestamp, 9 ether);

		//right now rewards are split equally between the node op and user. User provided half the total funds in this test
		minipoolMgr.recordStakingEnd{value: validationAmt + rewards}(mp1.nodeID, block.timestamp, rewards);
		uint256 commissionFee = (halfRewards * 15) / 100;
		//checking the node operators rewards are corrrect
		assertEq(vault.balanceOf("MinipoolManager"), (depositAmt + halfRewards + commissionFee));

		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);
		assertEq(mp1Updated.status, uint256(MinipoolStatus.Withdrawable));
		assertEq(mp1Updated.avaxTotalRewardAmt, rewards);
		assertTrue(mp1Updated.endTime != 0);
		assertEq(mp1Updated.avaxNodeOpRewardAmt, (halfRewards + commissionFee));
		assertEq(mp1Updated.avaxLiquidStakerRewardAmt, (halfRewards - commissionFee));

		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 0);

		assertEq(staking.getAVAXAssigned(mp1Updated.owner), 0);
		assertEq(staking.getMinipoolCount(mp1Updated.owner), 0);
	}

	function testRecordStakingEndWithSlash() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);

		bytes32 txID = keccak256("txid");
		vm.prank(address(rialto));
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);

		//will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Error));
		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Staking));

		vm.startPrank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidEndTime.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);

		skip(duration);

		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingEnd{value: 0 ether}(mp1.nodeID, block.timestamp, 0 ether);

		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 9 ether);

		minipoolMgr.recordStakingEnd{value: validationAmt}(mp1.nodeID, block.timestamp, 0 ether);

		assertEq(vault.balanceOf("MinipoolManager"), depositAmt);

		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);
		assertEq(mp1Updated.status, uint256(MinipoolStatus.Withdrawable));
		assertEq(mp1Updated.avaxTotalRewardAmt, 0);
		assertTrue(mp1Updated.endTime != 0);

		assertEq(mp1Updated.avaxNodeOpRewardAmt, 0);
		assertEq(mp1Updated.avaxLiquidStakerRewardAmt, 0);

		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 0);

		assertEq(staking.getAVAXAssigned(mp1Updated.owner), 0);
		assertEq(staking.getMinipoolCount(mp1Updated.owner), 0);

		assertGt(mp1Updated.ggpSlashAmt, 0);
		assertLt(staking.getGGPStake(mp1Updated.owner), ggpStakeAmt);
	}

	function testRecordStakingError() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp1.nodeID);

		bytes32 txID = keccak256("txid");
		vm.prank(address(rialto));
		minipoolMgr.recordStakingStart(mp1.nodeID, txID, block.timestamp);

		bytes32 errorCode = "INVALID_NODEID";

		//will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.recordStakingError{value: validationAmt}(mp1.nodeID, errorCode);

		//will fail
		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Prelaunch));

		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.recordStakingError{value: validationAmt}(mp1.nodeID, errorCode);

		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Staking));

		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingError{value: 0 ether}(mp1.nodeID, errorCode);

		vm.prank(address(rialto));
		minipoolMgr.recordStakingError{value: validationAmt}(mp1.nodeID, errorCode);

		assertEq(vault.balanceOf("MinipoolManager"), depositAmt);

		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);
		assertEq(mp1Updated.status, uint256(MinipoolStatus.Error));
		assertEq(mp1Updated.avaxTotalRewardAmt, 0);
		assertEq(mp1Updated.errorCode, errorCode);
		assertEq(mp1Updated.avaxNodeOpRewardAmt, 0);
		assertEq(mp1Updated.avaxLiquidStakerRewardAmt, 0);

		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 0);

		assertEq(staking.getAVAXAssigned(mp1Updated.owner), 0);
		// The highwater doesnt get reset in this case
		assertEq(staking.getAVAXAssignedHighWater(mp1Updated.owner), depositAmt);

		// Test that multisig can move status to Finished after some kind of human review of error

		// will fail
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.finishFailedMinipoolByMultisig(mp1Updated.nodeID);

		vm.prank(address(rialto));
		minipoolMgr.finishFailedMinipoolByMultisig(mp1Updated.nodeID);
		MinipoolManager.Minipool memory mp1finished = minipoolMgr.getMinipool(minipoolIndex);

		assertEq(mp1finished.status, uint256(MinipoolStatus.Finished));
	}

	function testCancelMinipoolByMultisig() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp1 = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		uint256 priorBalance = nodeOp.balance;

		bytes32 errorCode = "INVALID_NODEID";

		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.cancelMinipoolByMultisig(mp1.nodeID, errorCode);

		int256 minipoolIndex = minipoolMgr.getIndexOf(mp1.nodeID);
		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Staking));

		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InvalidStateTransition.selector);
		minipoolMgr.cancelMinipoolByMultisig(mp1.nodeID, errorCode);

		store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Prelaunch));

		vm.prank(address(rialto));
		minipoolMgr.cancelMinipoolByMultisig(mp1.nodeID, errorCode);

		MinipoolManager.Minipool memory mp1Updated = minipoolMgr.getMinipool(minipoolIndex);
		assertEq(mp1Updated.status, uint256(MinipoolStatus.Canceled));
		assertEq(mp1Updated.errorCode, errorCode);

		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 0);

		assertEq(staking.getAVAXAssigned(mp1Updated.owner), 0);
		assertEq(staking.getAVAXStake(mp1Updated.owner), 0);
		assertEq(staking.getMinipoolCount(mp1Updated.owner), 0);

		assertEq(nodeOp.balance - priorBalance, depositAmt);
	}

	function testExpectedRewards() public {
		uint256 amt = minipoolMgr.getExpectedAVAXRewardsAmt(365 days, 1_000 ether);
		assertEq(amt, 100 ether);
		amt = minipoolMgr.getExpectedAVAXRewardsAmt((365 days / 2), 1_000 ether);
		assertEq(amt, 50 ether);
		amt = minipoolMgr.getExpectedAVAXRewardsAmt((365 days / 3), 1_000 ether);
		assertEq(amt, 33333333333333333333);

		// Set 5% annual expected rewards rate
		vm.prank(address(rialto));
		dao.setExpectedAVAXRewardsRate(5e16);
		amt = minipoolMgr.getExpectedAVAXRewardsAmt(365 days, 1_000 ether);
		assertEq(amt, 50 ether);
		amt = minipoolMgr.getExpectedAVAXRewardsAmt((365 days / 3), 1_000 ether);
		assertEq(amt, 16.666666666666666666 ether);
	}

	function testGetMinipool() public {
		address nodeID = address(1);
		uint256 duration = 2 weeks;
		uint256 delegationFee = 20;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 nopAvaxAmount = 1000 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(100 ether);
		minipoolMgr.createMinipool{value: nopAvaxAmount}(nodeID, duration, delegationFee, avaxAssignmentRequest);

		int256 minipoolIndex = minipoolMgr.getIndexOf(nodeID);
		MinipoolManager.Minipool memory mp = minipoolMgr.getMinipool(minipoolIndex);

		assertEq(mp.nodeID, nodeID);
		assertEq(mp.status, uint256(MinipoolStatus.Prelaunch));
		assertEq(mp.duration, duration);
		assertEq(mp.delegationFee, delegationFee);
		assertEq(mp.avaxLiquidStakerAmt, avaxAssignmentRequest);
		assertEq(mp.avaxNodeOpAmt, nopAvaxAmount);
		assertEq(mp.owner, address(nodeOp));
	}

	function testGetMinipools() public {
		address nodeID;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 depositAmt = 1000 ether;
		uint128 ggpStakeAmt = 100 ether;

		vm.startPrank(nodeOp);
		for (uint256 i = 0; i < 10; i++) {
			nodeID = randAddress();
			ggp.approve(address(staking), ggpStakeAmt);
			staking.stakeGGP(ggpStakeAmt);
			minipoolMgr.createMinipool{value: depositAmt}(nodeID, 0, 0, avaxAssignmentRequest);
		}
		vm.stopPrank();

		index = minipoolMgr.getIndexOf(nodeID);
		assertEq(index, 9);

		MinipoolManager.Minipool[] memory mps = minipoolMgr.getMinipools(MinipoolStatus.Prelaunch, 0, 0);
		assertEq(mps.length, 10);

		for (uint256 i = 0; i < 5; i++) {
			int256 minipoolIndex = minipoolMgr.getIndexOf(mps[i].nodeID);
			store.setUint(keccak256(abi.encodePacked("minipool.item", minipoolIndex, ".status")), uint256(MinipoolStatus.Launched));
		}
		MinipoolManager.Minipool[] memory mps1 = minipoolMgr.getMinipools(MinipoolStatus.Launched, 0, 0);
		assertEq(mps1.length, 5);
	}

	function testGetMinipoolCount() public {
		address nodeID;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 depositAmt = 1000 ether;
		uint128 ggpStakeAmt = 100 ether;

		vm.startPrank(nodeOp);
		for (uint256 i = 0; i < 10; i++) {
			nodeID = randAddress();
			ggp.approve(address(staking), ggpStakeAmt);
			staking.stakeGGP(ggpStakeAmt);
			minipoolMgr.createMinipool{value: depositAmt}(nodeID, 0, 0, avaxAssignmentRequest);
		}
		vm.stopPrank();
		assertEq(minipoolMgr.getMinipoolCount(), 10);
	}

	function testCalculateGGPSlashAmt() public {
		vm.prank(address(rialto));
		oracle.setGGPPriceInAVAX(1 ether, block.timestamp);
		uint256 slashAmt = minipoolMgr.calculateGGPSlashAmt(100 ether);
		assertEq(slashAmt, 100 ether);

		vm.prank(address(rialto));
		oracle.setGGPPriceInAVAX(0.5 ether, block.timestamp);
		slashAmt = minipoolMgr.calculateGGPSlashAmt(100 ether);
		assertEq(slashAmt, 200 ether);

		vm.prank(address(rialto));
		oracle.setGGPPriceInAVAX(3 ether, block.timestamp);
		slashAmt = minipoolMgr.calculateGGPSlashAmt(100 ether);
		assertEq(slashAmt, 33333333333333333333);
	}

	function testFullCycle_WithUserFunds() public {
		uint256 originalRialtoBalance = address(rialto).balance;
		address lilly = getActorWithTokens("lilly", MAX_AMT, MAX_AMT);
		vm.prank(lilly);
		ggAVAX.depositAVAX{value: MAX_AMT}();
		assertEq(lilly.balance, 0);

		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), ggpStakeAmt);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		assertEq(vault.balanceOf("MinipoolManager"), depositAmt);

		vm.startPrank(address(rialto));

		minipoolMgr.claimAndInitiateStaking(mp.nodeID);

		assertEq(vault.balanceOf("MinipoolManager"), 0);
		assertEq(address(rialto).balance - originalRialtoBalance, validationAmt);

		bytes32 txID = keccak256("txid");
		minipoolMgr.recordStakingStart(mp.nodeID, txID, block.timestamp);

		vm.expectRevert(MinipoolManager.InvalidEndTime.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt}(mp.nodeID, block.timestamp, 0 ether);

		skip(duration);

		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingEnd{value: 0 ether}(mp.nodeID, block.timestamp, 0 ether);

		uint256 rewards = 10 ether;

		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingEnd{value: validationAmt + rewards}(mp.nodeID, block.timestamp, 9 ether);

		//right now rewards are split equally between the node op and user. User provided half the total funds in this test
		minipoolMgr.recordStakingEnd{value: validationAmt + rewards}(mp.nodeID, block.timestamp, 10 ether);
		uint256 commissionFee = (5 ether * 15) / 100;
		//checking the node operators rewards are corrrect
		assertEq(vault.balanceOf("MinipoolManager"), (1005 ether + commissionFee));

		vm.stopPrank();

		///test that the node op can withdraw the funds they are due
		vm.startPrank(nodeOp);
		uint256 priorBalance_nodeOp = nodeOp.balance;

		minipoolMgr.withdrawMinipoolFunds(mp.nodeID);
		assertEq((nodeOp.balance - priorBalance_nodeOp), (1005 ether + commissionFee));
	}

	function testFullCycle_Error() public {
		address lilly = getActorWithTokens("lilly", MAX_AMT, MAX_AMT);
		vm.prank(lilly);
		ggAVAX.depositAVAX{value: MAX_AMT}();
		assertEq(lilly.balance, 0);

		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		uint128 ggpStakeAmt = 200 ether;
		uint256 amountAvailForStaking = ggAVAX.amountAvailableForStaking();
		uint256 originalRialtoBalance = address(rialto).balance;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), ggpStakeAmt);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		assertEq(vault.balanceOf("MinipoolManager"), depositAmt);

		vm.startPrank(address(rialto));

		minipoolMgr.claimAndInitiateStaking(mp.nodeID);

		assertEq(vault.balanceOf("MinipoolManager"), 0);
		assertEq(address(rialto).balance - originalRialtoBalance, validationAmt);
		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), avaxAssignmentRequest);

		// Assume something goes wrong and we are unable to launch a minipool

		bytes32 errorCode = "INVALID_NODEID";

		// Expect revert on sending wrong amt
		vm.expectRevert(MinipoolManager.InvalidAmount.selector);
		minipoolMgr.recordStakingError{value: 0}(mp.nodeID, errorCode);

		// Now send correct amt
		minipoolMgr.recordStakingError{value: validationAmt}(mp.nodeID, errorCode);
		assertEq(address(rialto).balance - originalRialtoBalance, 0);
		// NodeOps funds should be back in vault
		assertEq(vault.balanceOf("MinipoolManager"), depositAmt);
		// Liq stakers funds should be returned
		assertEq(ggAVAX.amountAvailableForStaking(), amountAvailForStaking);
		assertEq(minipoolMgr.getTotalAVAXLiquidStakerAmt(), 0);

		mp = minipoolMgr.getMinipool(mp.index);
		assertEq(mp.status, uint256(MinipoolStatus.Error));
		assertEq(mp.errorCode, errorCode);
	}

	function testRecreateMinipool() public {
		uint256 duration = 4 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint256 validationAmt = depositAmt + avaxAssignmentRequest;
		// Enough to start but not to re-stake, we will add more later
		uint128 ggpStakeAmt = 100 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), MAX_AMT);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		vm.stopPrank();

		address liqStaker1 = getActorWithTokens("liqStaker1", MAX_AMT, MAX_AMT);
		vm.prank(liqStaker1);
		ggAVAX.depositAVAX{value: MAX_AMT}();

		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp.nodeID);

		bytes32 txID = keccak256("txid");
		vm.prank(address(rialto));
		minipoolMgr.recordStakingStart(mp.nodeID, txID, block.timestamp);

		skip(duration / 2);

		// Give rialto the rewards it needs
		uint256 rewards = 10 ether;
		deal(address(rialto), address(rialto).balance + rewards);

		// Pay out the rewards
		vm.prank(address(rialto));
		minipoolMgr.recordStakingEnd{value: validationAmt + rewards}(mp.nodeID, block.timestamp, rewards);

		// Now try to restake
		vm.expectRevert(MinipoolManager.InvalidMultisigAddress.selector);
		minipoolMgr.recreateMinipool(mp.nodeID);

		vm.prank(address(rialto));
		vm.expectRevert(MinipoolManager.InsufficientGGPCollateralization.selector);
		minipoolMgr.recreateMinipool(mp.nodeID);

		// Add a bit more collateral to cover the compounding rewards
		vm.prank(nodeOp);
		staking.stakeGGP(1 ether);

		vm.prank(address(rialto));
		minipoolMgr.recreateMinipool(mp.nodeID);

		MinipoolManager.Minipool memory mpCompounded = minipoolMgr.getMinipoolByNodeID(mp.nodeID);
		assertEq(mpCompounded.status, uint256(MinipoolStatus.Prelaunch));
		assertGt(mpCompounded.avaxNodeOpAmt, mp.avaxNodeOpAmt);
		assertGt(mpCompounded.avaxNodeOpAmt, mp.avaxNodeOpInitialAmt);
		assertGt(mpCompounded.avaxLiquidStakerAmt, mp.avaxLiquidStakerAmt);
		assertEq(staking.getAVAXStake(mp.owner), mpCompounded.avaxNodeOpAmt);
		assertEq(staking.getAVAXAssigned(mp.owner), mpCompounded.avaxLiquidStakerAmt);
		assertEq(staking.getMinipoolCount(mp.owner), 1);
		assertEq(mpCompounded.startTime, 0);
		assertGt(mpCompounded.initialStartTime, 0);
	}

	function testBondZeroGGP() public {
		vm.startPrank(nodeOp);
		address nodeID = randAddress();
		uint256 avaxAssignmentRequest = 1000 ether;

		vm.expectRevert(Staking.StakerNotFound.selector); //no ggp will be staked under the address, so it will fail upon lookup
		minipoolMgr.createMinipool{value: 1000 ether}(nodeID, 0, 0, avaxAssignmentRequest);
		vm.stopPrank();
	}

	function testUndercollateralized() public {
		vm.startPrank(nodeOp);
		address nodeID = randAddress();
		uint256 avaxAmt = 1000 ether;
		uint256 ggpStakeAmt = 50 ether; // 5%
		ggp.approve(address(staking), ggpStakeAmt);
		staking.stakeGGP(ggpStakeAmt);
		vm.expectRevert(MinipoolManager.InsufficientGGPCollateralization.selector); //no ggp will be staked under the address, so it will fail upon lookup
		minipoolMgr.createMinipool{value: avaxAmt}(nodeID, 0, 0, avaxAmt);
		vm.stopPrank();
	}

	function testEmptyState() public {
		vm.startPrank(nodeOp);
		index = minipoolMgr.getIndexOf(ZERO_ADDRESS);
		assertEq(index, -1);
		MinipoolManager.Minipool memory mp;
		mp = minipoolMgr.getMinipool(index);
		assertEq(mp.nodeID, ZERO_ADDRESS);
		vm.stopPrank();
	}

	// Maybe we have testGas... tests that just do a single important operation
	// to make it easier to monitor gas usage
	function testGasCreateMinipool() public {
		uint256 duration = 2 weeks;
		uint256 depositAmt = 1000 ether;
		uint256 avaxAssignmentRequest = 1000 ether;
		uint128 ggpStakeAmt = 200 ether;

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), ggpStakeAmt);
		staking.stakeGGP(ggpStakeAmt);
		startMeasuringGas("testGasCreateMinipool");
		MinipoolManager.Minipool memory mp = createMinipool(depositAmt, avaxAssignmentRequest, duration);
		stopMeasuringGas();
		vm.stopPrank();

		index = minipoolMgr.getIndexOf(mp.nodeID);
		assertFalse(index == -1);
	}

	function testCreateAndGetMany() public {
		address nodeID;
		uint256 avaxAssignmentRequest = 1000 ether;

		for (uint256 i = 0; i < 10; i++) {
			nodeID = randAddress();
			vm.startPrank(nodeOp);
			ggp.approve(address(staking), 100 ether);
			staking.stakeGGP(100 ether);
			minipoolMgr.createMinipool{value: 1000 ether}(nodeID, 0, 0, avaxAssignmentRequest);
			vm.stopPrank();
		}
		index = minipoolMgr.getIndexOf(nodeID);
		assertEq(index, 9);
	}

	function updateMinipoolStatus(address nodeID, MinipoolStatus newStatus) public {
		int256 i = minipoolMgr.getIndexOf(nodeID);
		assertTrue((i != -1), "Minipool not found");
		vm.prank(guardian);
		store.setUint(keccak256(abi.encodePacked("MinipoolManager.item", i, ".status")), uint256(newStatus));
	}
}
