// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {format} from "../src/format.sol";

contract formatTest is Test {
	function testParseEther() public {
		string memory result = format.parseEther(0.56565 ether);
		assertEq(result, "0.56565");
	}
}
