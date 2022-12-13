// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Strings} from "./dependencies/Strings.sol";

library format {
	function parseEther(uint256 e) public pure returns (string memory) {
		uint256 sigDigits = 100_000;
		uint256 result = (e * sigDigits) / 1 ether;

		return string.concat(Strings.toString(result / sigDigits), ".", Strings.toString(result % sigDigits));
	}
}
