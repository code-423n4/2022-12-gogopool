// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OneInchMock {
	uint256 public mockedRate = 1 ether;

	function setMockedRate(uint256 rate) public {
		mockedRate = rate;
	}

	function getRateToEth(IERC20 srcToken, bool useSrcWrappers) external view returns (uint256 weightedRate) {
		srcToken; // silence linter
		useSrcWrappers; // silence linter
		weightedRate = mockedRate;
	}
}
