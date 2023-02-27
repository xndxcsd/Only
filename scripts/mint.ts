import { ethers } from "hardhat";

async function main() {
	const Only = await ethers.getContractFactory("Only");
	const only = await Only.attach("0x58fd481dea1BF666CB6533eC013101813296cA7E");

	// await only.mint(1, {value : ethers.utils.parseEther("0.001")});
	
	// await setTimeout(async function () {
	console.log(await only.balanceOf(only.signer.getAddress()));
	// }, 1000)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
