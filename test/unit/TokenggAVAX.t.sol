// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./utils/BaseTest.sol";
import {BaseAbstract} from "../../contracts/contract/BaseAbstract.sol";

contract TokenggAVAXTest is BaseTest, IWithdrawer {
	using FixedPointMathLib for uint256;

	address private alice;
	address private bob;
	address private nodeID;
	uint256 private duration;
	uint256 private delegationFee;

	function setUp() public override {
		super.setUp();
		vm.prank(guardian);
		store.setUint(keccak256("ProtocolDAO.TargetGGAVAXReserveRate"), 0.1 ether);

		alice = getActorWithTokens("alice", MAX_AMT, MAX_AMT);
		bob = getActor("bob");

		nodeID = randAddress();
		duration = 2 weeks;
		delegationFee = 20_000;
		uint256 avaxAssignmentRequest = 1000 ether;
		vm.startPrank(alice);
		ggp.approve(address(staking), 100 ether);
		staking.stakeGGP(100 ether);
		minipoolMgr.createMinipool{value: 1000 ether}(nodeID, duration, delegationFee, avaxAssignmentRequest);
		vm.stopPrank();
	}

	function testTokenSetup() public {
		assertEq(ggAVAX.name(), "GoGoPool Liquid Staking Token");
		assertEq(ggAVAX.decimals(), uint8(18));
		assertEq(ggAVAX.symbol(), "ggAVAX");
	}

	function testReinitialization() public {
		vm.expectRevert(bytes("Initializable: contract is already initialized"));
		ggAVAX.initialize(store, wavax);
	}

	function testSingleDepositWithdrawWAVAX(uint128 amount) public {
		vm.assume(amount != 0 && amount < MAX_AMT);

		uint256 aliceUnderlyingAmount = amount;

		uint256 alicePreDepositBal = wavax.balanceOf(alice);

		vm.startPrank(alice);
		wavax.approve(address(ggAVAX), aliceUnderlyingAmount);
		uint256 aliceShareAmount = ggAVAX.deposit(aliceUnderlyingAmount, alice);
		vm.stopPrank();

		// Expect exchange rate to be 1:1 on initial deposit.
		assertEq(aliceUnderlyingAmount, aliceShareAmount);
		assertEq(ggAVAX.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
		assertEq(ggAVAX.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
		assertEq(ggAVAX.totalSupply(), aliceShareAmount);
		assertEq(ggAVAX.totalAssets(), aliceUnderlyingAmount);
		assertEq(ggAVAX.balanceOf(alice), aliceShareAmount);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(alice)), aliceUnderlyingAmount);
		assertEq(wavax.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

		vm.startPrank(alice);
		wavax.approve(address(ggAVAX), aliceUnderlyingAmount);
		ggAVAX.withdraw(aliceUnderlyingAmount, alice, alice);
		vm.stopPrank();

		assertEq(ggAVAX.totalAssets(), 0);
		assertEq(ggAVAX.balanceOf(alice), 0);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(alice)), 0);
		assertEq(wavax.balanceOf(alice), alicePreDepositBal);
	}

	function testSingleDepositWithdrawAVAX(uint128 amount) public {
		vm.assume(amount != 0 && amount < MAX_AMT);

		uint256 aliceUnderlyingAmount = amount;
		uint256 alicePreDepositBal = alice.balance;
		vm.deal(alice, alicePreDepositBal + aliceUnderlyingAmount);

		vm.prank(alice);
		uint256 aliceShareAmount = ggAVAX.depositAVAX{value: aliceUnderlyingAmount}();

		// Expect exchange rate to be 1:1 on initial deposit.
		assertEq(aliceUnderlyingAmount, aliceShareAmount);
		assertEq(ggAVAX.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
		assertEq(ggAVAX.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
		assertEq(ggAVAX.totalSupply(), aliceShareAmount);
		assertEq(ggAVAX.totalAssets(), aliceUnderlyingAmount);
		assertEq(ggAVAX.balanceOf(alice), aliceShareAmount);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(alice)), aliceUnderlyingAmount);
		assertEq(alice.balance, alicePreDepositBal);

		vm.prank(alice);
		ggAVAX.withdrawAVAX(aliceUnderlyingAmount);

		assertEq(ggAVAX.totalAssets(), 0);
		assertEq(ggAVAX.balanceOf(alice), 0);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(alice)), 0);
		assertEq(alice.balance, alicePreDepositBal + aliceUnderlyingAmount);
	}

	function testSingleMintRedeem(uint128 amount) public {
		vm.assume(amount != 0 && amount < MAX_AMT);

		uint256 aliceShareAmount = amount;

		uint256 alicePreDepositBal = wavax.balanceOf(alice);

		vm.startPrank(alice);
		wavax.approve(address(ggAVAX), aliceShareAmount);
		uint256 aliceUnderlyingAmount = ggAVAX.mint(aliceShareAmount, alice);
		vm.stopPrank();

		// Expect exchange rate to be 1:1 on initial mint.
		assertEq(aliceShareAmount, aliceUnderlyingAmount);
		assertEq(ggAVAX.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
		assertEq(ggAVAX.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
		assertEq(ggAVAX.totalSupply(), aliceShareAmount);
		assertEq(ggAVAX.totalAssets(), aliceUnderlyingAmount);
		assertEq(ggAVAX.balanceOf(alice), aliceUnderlyingAmount);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(alice)), aliceUnderlyingAmount);
		assertEq(wavax.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

		vm.prank(alice);
		ggAVAX.redeem(aliceShareAmount, alice, alice);

		assertEq(ggAVAX.totalAssets(), 0);
		assertEq(ggAVAX.balanceOf(alice), 0);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(alice)), 0);
		assertEq(wavax.balanceOf(alice), alicePreDepositBal);
	}

	function testDepositStakingRewards() public {
		// Scenario:
		// 1. Bob mints 2000 shares (costs 2000 tokens)
		// 2. 1000 tokens are withdrawn for staking
		// 3. 1000 rewards deposited
		// 4. 1 rewards cycle pass, no rewards are distributed to
		// 		totalReleasedAssets
		// 5. Sync rewards
		// 6. Skip ahead 1/3 a cycle, bob's 4000 shares convert to
		//		4333 assets.
		// 7. Skip ahead remaining 2/3 of the rewards cycle,
		//		all rewards should be distributed

		uint256 depositAmount = 2000 ether;
		uint256 stakingWithdrawAmount = 1000 ether;
		uint256 totalStakedAmount = 2000 ether;

		uint256 rewardsAmount = 100 ether;
		uint256 liquidStakerRewards = 50 ether - ((50 ether * 15) / 100);

		uint256 rialtoInitBal = address(rialto).balance;

		// 1. Bob mints 1000 shares
		vm.deal(bob, depositAmount);
		vm.prank(bob);
		ggAVAX.depositAVAX{value: depositAmount}();

		assertEq(bob.balance, 0);
		assertEq(wavax.balanceOf(address(ggAVAX)), depositAmount);
		assertEq(ggAVAX.balanceOf(bob), depositAmount);
		assertEq(ggAVAX.convertToShares(ggAVAX.balanceOf(bob)), depositAmount);
		assertEq(ggAVAX.amountAvailableForStaking(), depositAmount - depositAmount.mulDivDown(dao.getTargetGGAVAXReserveRate(), 1 ether));

		// 2. 1000 tokens are withdrawn for staking
		vm.prank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(nodeID);

		assertEq(address(rialto).balance, rialtoInitBal + totalStakedAmount);
		assertEq(ggAVAX.totalAssets(), depositAmount);
		assertEq(ggAVAX.stakingTotalAssets(), stakingWithdrawAmount);

		// 3. 1000 rewards are deposited
		// None of these rewards should be distributed yet
		vm.deal(address(rialto), address(rialto).balance + rewardsAmount);
		vm.startPrank(address(rialto));
		bytes32 txID = keccak256("txid");
		minipoolMgr.recordStakingStart(nodeID, txID, block.timestamp);
		int256 idx = minipoolMgr.getIndexOf(nodeID);
		MinipoolManager.Minipool memory mp = minipoolMgr.getMinipool(idx);
		uint256 endTime = block.timestamp + mp.duration;

		skip(mp.duration);
		minipoolMgr.recordStakingEnd{value: totalStakedAmount + rewardsAmount}(nodeID, endTime, rewardsAmount);
		vm.stopPrank();

		assertEq(address(rialto).balance, rialtoInitBal);
		assertEq(ggAVAX.totalAssets(), depositAmount);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(bob)), depositAmount);

		// 4. Skip ahead one rewards cycle
		// Still no rewards should be distributed
		skip(ggAVAX.rewardsCycleLength());
		assertEq(ggAVAX.totalAssets(), depositAmount);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(bob)), depositAmount);

		// 5. Sync rewards and see an update to half the rewards
		ggAVAX.syncRewards();
		assertEq(ggAVAX.totalAssets(), depositAmount);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(bob)), depositAmount);
		assertEq(ggAVAX.lastRewardsAmt(), liquidStakerRewards);

		// 6. Skip 1/3 of rewards length and see 1/3 rewards in totalReleasedAssets
		skip(ggAVAX.rewardsCycleLength() / 3);

		uint256 partialRewards = (liquidStakerRewards * (block.timestamp - ggAVAX.lastSync())) / (ggAVAX.rewardsCycleEnd() - ggAVAX.lastSync());
		assertEq(uint256(ggAVAX.totalAssets()), uint256(depositAmount) + partialRewards);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(bob)), depositAmount + partialRewards);
		assertEq(ggAVAX.lastRewardsAmt(), liquidStakerRewards);

		// 7. Skip 2/3 of rewards length
		// Rewards should be fully distributed
		skip((ggAVAX.rewardsCycleLength() * 2) / 3);
		assertEq(ggAVAX.totalAssets(), depositAmount + liquidStakerRewards);
		assertEq(ggAVAX.convertToAssets(ggAVAX.balanceOf(bob)), depositAmount + liquidStakerRewards);
	}

	function testAmountAvailableForStaking() public {
		uint256 depositAmount = 1000 ether;

		vm.deal(bob, depositAmount);
		vm.prank(bob);
		ggAVAX.depositAVAX{value: depositAmount}();

		assertEq(bob.balance, 0);
		assertEq(wavax.balanceOf(address(ggAVAX)), depositAmount);
		assertEq(ggAVAX.balanceOf(bob), depositAmount);
		assertEq(ggAVAX.convertToShares(ggAVAX.balanceOf(bob)), depositAmount);
		uint256 reservedAssets = ggAVAX.totalAssets().mulDivDown(dao.getTargetGGAVAXReserveRate(), 1 ether);
		assertEq(ggAVAX.amountAvailableForStaking(), depositAmount - reservedAssets);
	}

	function testWithdrawForStaking() public {
		// Deposit liquid staker funds
		uint256 depositAmount = 1200 ether;
		uint256 nodeAmt = 2000 ether;
		uint128 ggpStakeAmt = 200 ether;

		vm.deal(bob, depositAmount);
		vm.prank(bob);
		ggAVAX.depositAVAX{value: depositAmount}();

		assertEq(ggAVAX.previewWithdraw(depositAmount), depositAmount);
		assertEq(ggAVAX.maxWithdraw(bob), depositAmount);
		assertEq(ggAVAX.previewRedeem(depositAmount), depositAmount);
		assertEq(ggAVAX.maxRedeem(bob), depositAmount);

		// Create and claim minipool
		address nodeOp = getActorWithTokens("nodeOp", uint128(depositAmount), ggpStakeAmt);

		vm.startPrank(nodeOp);
		ggp.approve(address(staking), ggpStakeAmt);
		staking.stakeGGP(ggpStakeAmt);
		MinipoolManager.Minipool memory mp = createMinipool(nodeAmt / 2, nodeAmt / 2, duration);
		vm.stopPrank();

		vm.startPrank(address(rialto));
		minipoolMgr.claimAndInitiateStaking(mp.nodeID);
		minipoolMgr.recordStakingStart(mp.nodeID, randHash(), block.timestamp);
		vm.stopPrank();

		assertEq(ggAVAX.previewWithdraw(depositAmount), depositAmount);
		assertEq(ggAVAX.maxWithdraw(bob), ggAVAX.totalAssets() - ggAVAX.stakingTotalAssets());
		assertEq(ggAVAX.previewRedeem(depositAmount), depositAmount);
		assertEq(ggAVAX.maxRedeem(bob), ggAVAX.totalAssets() - ggAVAX.stakingTotalAssets());

		skip(mp.duration);

		uint256 rewardsAmt = nodeAmt.mulDivDown(0.1 ether, 1 ether);

		vm.deal(address(rialto), address(rialto).balance + rewardsAmt);
		vm.prank(address(rialto));
		minipoolMgr.recordStakingEnd{value: nodeAmt + rewardsAmt}(mp.nodeID, block.timestamp, rewardsAmt);

		ggAVAX.syncRewards();
		skip(ggAVAX.rewardsCycleLength());

		// Now that rewards are added, maxRedeem = depositAmt (because shares havent changed), and maxWithdraw > depositAmt
		assertGt(ggAVAX.maxWithdraw(bob), depositAmount);
		assertEq(ggAVAX.maxRedeem(bob), depositAmount);

		// If we withdraw same number of assets, we will get less shares since they are worth more now
		assertLt(ggAVAX.previewWithdraw(depositAmount), depositAmount);
		// If we redeem all our shares we get more assets
		assertGt(ggAVAX.previewRedeem(depositAmount), depositAmount);
	}

	function testDepositFromStakingInvalid() public {
		uint256 totalAmt = 100 ether;
		uint256 baseAmt = 0;
		uint256 rewardAmt = 0;

		vm.deal(address(minipoolMgr), totalAmt);

		vm.startPrank(address(minipoolMgr));
		vm.expectRevert(TokenggAVAX.InvalidStakingDeposit.selector);
		ggAVAX.depositFromStaking{value: totalAmt}(baseAmt, rewardAmt);

		totalAmt = ggAVAX.stakingTotalAssets() + 1;
		baseAmt = ggAVAX.stakingTotalAssets() + 1;
		rewardAmt = 0;
		vm.expectRevert(TokenggAVAX.InvalidStakingDeposit.selector);
		ggAVAX.depositFromStaking{value: totalAmt}(baseAmt, rewardAmt);
	}

	function testDepositPause() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		bytes memory customError = abi.encodeWithSignature("ContractPaused()");
		vm.expectRevert(customError);
		ggAVAX.deposit(100 ether, alice);

		vm.expectRevert(bytes("ZERO_SHARES"));
		ggAVAX.deposit(0 ether, alice);
	}

	function testPreviewDepositPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.previewDeposit(100 ether);

		uint256 shares = ggAVAX.previewDeposit(0 ether);
		assertEq(shares, 0);
	}

	function testDepositAVAXPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.depositAVAX{value: 100 ether}();

		vm.expectRevert(TokenggAVAX.ZeroShares.selector);
		ggAVAX.depositAVAX{value: 0 ether}();
	}

	function testMintPause() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.mint(100 ether, alice);

		uint256 assets = ggAVAX.mint(0 ether, alice);
		assertEq(assets, 0);
	}

	function testPreviewMintPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.previewMint(100 ether);

		uint256 assets = ggAVAX.previewMint(0 ether);
		assertEq(assets, 0);
	}

	function testWithdrawPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.withdraw(100 ether, alice, alice);

		uint256 shares = ggAVAX.withdraw(0 ether, alice, alice);
		assertEq(shares, 0);
	}

	function testPreviewWithdrawPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.previewWithdraw(100 ether);

		uint256 shares = ggAVAX.previewWithdraw(0 ether);
		assertEq(shares, 0);
	}

	function testWithdrawAVAXPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.startPrank(alice);
		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.withdrawAVAX(100 ether);

		uint256 shares = ggAVAX.withdrawAVAX(0 ether);
		assertEq(shares, 0);
	}

	function testRedeemAVAXPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.redeemAVAX(100 ether);

		vm.expectRevert(TokenggAVAX.ZeroAssets.selector);
		ggAVAX.redeemAVAX(0 ether);
	}

	function testRedeemPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.startPrank(alice);
		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.redeem(100 ether, alice, alice);

		vm.expectRevert(bytes("ZERO_ASSETS"));
		ggAVAX.redeem(0 ether, alice, alice);
	}

	function testPreviewRedeemPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.expectRevert(BaseAbstract.ContractPaused.selector);
		ggAVAX.previewRedeem(100 ether);

		uint256 assets = ggAVAX.previewRedeem(0 ether);
		assertEq(assets, 0);
	}

	function testMaxWithdrawPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.deal(alice, 100 ether);
		vm.startPrank(alice);
		wavax.deposit{value: 100 ether}();
		wavax.approve(address(ggAVAX), 100 ether);

		uint256 assets = ggAVAX.maxWithdraw(alice);
		assertEq(assets, 0);
	}

	function testMaxRedeemPaused() public {
		vm.prank(address(ocyticus));
		dao.pauseContract("TokenggAVAX");

		vm.deal(alice, 100 ether);
		vm.startPrank(alice);
		wavax.deposit{value: 100 ether}();
		wavax.approve(address(ggAVAX), 100 ether);

		uint256 shares = ggAVAX.maxRedeem(alice);
		assertEq(shares, 0);
	}

	function receiveWithdrawalAVAX() external payable {}

	function printState(string memory message) internal view {
		uint256 reservedAssets = ggAVAX.totalAssets().mulDivDown(dao.getTargetGGAVAXReserveRate(), 1 ether);

		console.log("");
		console.log("STEP", message);
		console.log("---timestamps---");
		console.log("block timestamp", block.timestamp);
		console.log("rewardsCycleEnd", ggAVAX.rewardsCycleEnd());
		console.log("lastSync", ggAVAX.lastSync());

		console.log("---assets---");
		console.log("totalAssets", ggAVAX.totalAssets() / 1 ether);
		console.log("amountAvailableForStaking", ggAVAX.amountAvailableForStaking() / 1 ether);
		console.log("reserved", reservedAssets / 1 ether);
		console.log("stakingTotalAssets", ggAVAX.stakingTotalAssets() / 1 ether);

		console.log("---rewards---");
		console.log("lastRewardsAmt", ggAVAX.lastRewardsAmt() / 1 ether);
	}
}
