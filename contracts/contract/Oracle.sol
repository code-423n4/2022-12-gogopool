// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./Base.sol";
import {IOneInch} from "../interface/IOneInch.sol";
import {Storage} from "./Storage.sol";
import {TokenGGP} from "./tokens/TokenGGP.sol";

/*
	Data Storage Schema
	Oracle.OneInch = address of the One Inch price aggregator contract
	Oracle.GGPPriceInAVAX = price of GGP **IN AVAX UNITS**
	Oracle.GGPTimestamp = block.timestamp of last update to GGP price
*/

/// @title Interface for off-chain data
contract Oracle is Base {
	error InvalidGGPPrice();
	error InvalidTimestamp();

	event GGPPriceUpdated(uint256 indexed price, uint256 timestamp);

	constructor(Storage storageAddress) Base(storageAddress) {
		version = 1;
	}

	/// @notice Set the address of the One Inch price aggregator contract
	function setOneInch(address addr) external onlyGuardian {
		setAddress(keccak256("Oracle.OneInch"), addr);
	}

	/// @notice Get an aggregated price from the 1Inch contract.
	/// @dev NEVER call this on-chain, only off-chain oracle should call, then send a setGGPPriceInAVAX tx
	/// @return price of ggp in AVAX
	/// @return timestamp representing the current time
	function getGGPPriceInAVAXFromOneInch() external view returns (uint256 price, uint256 timestamp) {
		TokenGGP ggp = TokenGGP(getContractAddress("TokenGGP"));
		IOneInch oneinch = IOneInch(getAddress(keccak256("Oracle.OneInch")));
		price = oneinch.getRateToEth(ggp, false);
		timestamp = block.timestamp;
	}

	/// @notice Get the price of GGP denominated in AVAX
	/// @return price of ggp in AVAX
	/// @return timestamp representing when it was updated
	function getGGPPriceInAVAX() external view returns (uint256 price, uint256 timestamp) {
		price = getUint(keccak256("Oracle.GGPPriceInAVAX"));
		if (price == 0) {
			revert InvalidGGPPrice();
		}
		timestamp = getUint(keccak256("Oracle.GGPTimestamp"));
	}

	/// @notice Set the price of GGP denominated in AVAX
	/// @param price Price of GGP in AVAX
	/// @param timestamp Time the price was updated
	function setGGPPriceInAVAX(uint256 price, uint256 timestamp) external onlyMultisig {
		uint256 lastTimestamp = getUint(keccak256("Oracle.GGPTimestamp"));
		if (timestamp < lastTimestamp || timestamp > block.timestamp) {
			revert InvalidTimestamp();
		}
		if (price == 0) {
			revert InvalidGGPPrice();
		}
		setUint(keccak256("Oracle.GGPPriceInAVAX"), price);
		setUint(keccak256("Oracle.GGPTimestamp"), timestamp);
		emit GGPPriceUpdated(price, timestamp);
	}
}
