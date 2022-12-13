import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";

const { getNamedAccounts } = require("../tasks/lib/utils");

const deploy = async () => {
	const { deployer } = await getNamedAccounts();
	const Storage = await ethers.getContractFactory("Storage", deployer);
	const storage = await Storage.deploy();
	await storage.deployed();
	console.log("Storage deployed to", storage.address);

	const WAVAX = await ethers.getContractFactory("WAVAX", deployer);
	const wavax = await WAVAX.deploy();
	await wavax.deployed();
	console.log("WAVAX deployed to", wavax.address);

	const C = await ethers.getContractFactory("TokenggAVAX", deployer);
	const contract = await upgrades.deployProxy(
		C,
		[storage.address, wavax.address],
		{ kind: "uups" }
	);
	await contract.deployed();

	const inst = await contract.deployed();
	console.log(`${contract} deployed to: ${contract.address}`);
};

deploy()
	.then(() => {
		console.log("Done!");
		// eslint-disable-next-line no-process-exit
		process.exit(0);
	})
	.catch((error) => {
		console.error(error);
		throw error;
	});
