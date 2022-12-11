import { ethers, upgrades } from "hardhat";

const addresses = require(`../cache/deployed_addrs_${process.env.HARDHAT_NETWORK}`);

const upgrade = async () => {
	const Token = await ethers.getContractFactory("TokenggAVAX");
	const proxy = await upgrades.upgradeProxy(addresses.TokenggAVAX, Token);

	console.log(`Token contract upgraded`);
	console.log(`Proxy address: ${proxy.address}`);
	console.log(
		`Implementation address: ${await upgrades.erc1967.getImplementationAddress(
			proxy.address
		)}`
	);
};

upgrade()
	.then(() => {
		console.log("Done!");
	})
	.catch((error) => {
		console.error(error);
		throw error;
	});
