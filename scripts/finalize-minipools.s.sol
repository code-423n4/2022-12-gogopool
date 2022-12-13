// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
// import {console2} from "forge-std/console2.sol";
import {MinipoolManager} from "../contracts/contract/MinipoolManager.sol";
import {Storage} from "../contracts/contract/Storage.sol";
import {MinipoolStatus} from "../contracts/types/MinipoolStatus.sol";

contract FinalizeMinipools is Script {
	function run() external {
		address storageAddr = address(0xAE77fDd010D498678FCa3cC23e6E11f120Bf576c);
		// Not working for me? vm.envAddress not found
		// address storageAddr = vm.envAddress("STORAGE");
		Storage s = Storage(storageAddr);
		address mpAddr = s.getAddress(keccak256(abi.encodePacked("contract.address", "MinipoolManager")));
		MinipoolManager mp = MinipoolManager(mpAddr);

		MinipoolManager.Minipool[] memory minipools;
		minipools = mp.getMinipools(MinipoolStatus.Withdrawable, 0, 0);

		for (uint256 i = 0; i < minipools.length; i++) {
			// Set nodeID to the index, so its unique but not a real nodeID anymore
			address fakeAddr = address(uint160(uint256((minipools[i].index))));
			if (minipools[i].nodeID != fakeAddr) {
				console2.log(minipools[i].nodeID);
				vm.startBroadcast();
				s.setUint(keccak256(abi.encodePacked("minipool.index", minipools[i].nodeID)), 0);
				s.setUint(keccak256(abi.encodePacked("minipool.index", fakeAddr)), uint256(minipools[i].index));
				s.setAddress(keccak256(abi.encodePacked("minipool.item", minipools[i].index, ".nodeID")), fakeAddr);
				vm.stopBroadcast();
			}
		}
	}
}
