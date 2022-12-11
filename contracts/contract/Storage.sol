// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/// @title The primary persistent storage for GoGoPool
/// Based on RocketStorage by RocketPool

contract Storage {
	error InvalidGuardianConfirmation();
	error InvalidOrOutdatedContract();
	error MustBeGuardian();

	event GuardianChanged(address oldGuardian, address newGuardian);

	// Storage maps
	mapping(bytes32 => address) private addressStorage;
	mapping(bytes32 => bool) private booleanStorage;
	mapping(bytes32 => bytes) private bytesStorage;
	mapping(bytes32 => bytes32) private bytes32Storage;
	mapping(bytes32 => int256) private intStorage;
	mapping(bytes32 => string) private stringStorage;
	mapping(bytes32 => uint256) private uintStorage;

	// Guardian address
	address private guardian;
	address public newGuardian;

	/// @dev Only allow access from guardian or the latest version of a contract in the GoGoPool network
	modifier onlyRegisteredNetworkContract() {
		if (booleanStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))] == false && msg.sender != guardian) {
			revert InvalidOrOutdatedContract();
		}
		_;
	}

	constructor() {
		emit GuardianChanged(address(0), msg.sender);
		guardian = msg.sender;
	}

	// Initiate transfer of guardianship to a new address
	function setGuardian(address newAddress) external {
		// Check tx comes from current guardian
		if (msg.sender != guardian) {
			revert MustBeGuardian();
		}
		// Store new address awaiting confirmation
		newGuardian = newAddress;
	}

	// Get guardian address
	function getGuardian() external view returns (address) {
		return guardian;
	}

	// Completes transfer of guardianship
	function confirmGuardian() external {
		if (msg.sender != newGuardian) {
			revert InvalidGuardianConfirmation();
		}
		// Store old guardian for event
		address oldGuardian = guardian;
		// Update guardian and clear storage
		guardian = newGuardian;
		delete newGuardian;
		emit GuardianChanged(oldGuardian, guardian);
	}

	//
	// GET
	//

	function getAddress(bytes32 key) external view returns (address) {
		return addressStorage[key];
	}

	function getBool(bytes32 key) external view returns (bool) {
		return booleanStorage[key];
	}

	function getBytes(bytes32 key) external view returns (bytes memory) {
		return bytesStorage[key];
	}

	function getBytes32(bytes32 key) external view returns (bytes32) {
		return bytes32Storage[key];
	}

	function getInt(bytes32 key) external view returns (int256) {
		return intStorage[key];
	}

	function getString(bytes32 key) external view returns (string memory) {
		return stringStorage[key];
	}

	function getUint(bytes32 key) external view returns (uint256) {
		return uintStorage[key];
	}

	//
	// SET
	//

	function setAddress(bytes32 key, address value) external onlyRegisteredNetworkContract {
		addressStorage[key] = value;
	}

	function setBool(bytes32 key, bool value) external onlyRegisteredNetworkContract {
		booleanStorage[key] = value;
	}

	function setBytes(bytes32 key, bytes calldata value) external onlyRegisteredNetworkContract {
		bytesStorage[key] = value;
	}

	function setBytes32(bytes32 key, bytes32 value) external onlyRegisteredNetworkContract {
		bytes32Storage[key] = value;
	}

	function setInt(bytes32 key, int256 value) external onlyRegisteredNetworkContract {
		intStorage[key] = value;
	}

	function setString(bytes32 key, string calldata value) external onlyRegisteredNetworkContract {
		stringStorage[key] = value;
	}

	function setUint(bytes32 key, uint256 value) external onlyRegisteredNetworkContract {
		uintStorage[key] = value;
	}

	//
	// DELETE
	//

	function deleteAddress(bytes32 key) external onlyRegisteredNetworkContract {
		delete addressStorage[key];
	}

	function deleteBool(bytes32 key) external onlyRegisteredNetworkContract {
		delete booleanStorage[key];
	}

	function deleteBytes(bytes32 key) external onlyRegisteredNetworkContract {
		delete bytesStorage[key];
	}

	function deleteBytes32(bytes32 key) external onlyRegisteredNetworkContract {
		delete bytes32Storage[key];
	}

	function deleteInt(bytes32 key) external onlyRegisteredNetworkContract {
		delete intStorage[key];
	}

	function deleteString(bytes32 key) external onlyRegisteredNetworkContract {
		delete stringStorage[key];
	}

	function deleteUint(bytes32 key) external onlyRegisteredNetworkContract {
		delete uintStorage[key];
	}

	//
	// ADD / SUBTRACT HELPERS
	//

	/// @param key The key for the record
	/// @param amount An amount to add to the record's value
	function addUint(bytes32 key, uint256 amount) external onlyRegisteredNetworkContract {
		uintStorage[key] = uintStorage[key] + amount;
	}

	/// @param key The key for the record
	/// @param amount An amount to subtract from the record's value
	function subUint(bytes32 key, uint256 amount) external onlyRegisteredNetworkContract {
		uintStorage[key] = uintStorage[key] - amount;
	}
}
