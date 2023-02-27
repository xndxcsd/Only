import { ethers } from "hardhat";

async function main() {
	const Only = await ethers.getContractFactory("Only");
	const only = await Only.attach("0xAcdD09a7Cb02B08D2a587732FC8D6A205bfeEcf5");

	await only.mint(1, {value : ethers.utils.parseEther("0.001")});
	
	// await setTimeout(async function () {
	// console.log(await only.balanceOf(only.signer.getAddress()));
	// }, 1000)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
