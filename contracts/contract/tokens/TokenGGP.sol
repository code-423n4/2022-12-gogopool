// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

// GGP Governance and Utility Token
// Inflationary with rate determined by DAO

contract TokenGGP is ERC20 {
	uint256 private constant TOTAL_SUPPLY = 22_500_000 ether;

	constructor() ERC20("GoGoPool Protocol", "GGP", 18) {
		_mint(msg.sender, TOTAL_SUPPLY);
	}
}
