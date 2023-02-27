import { ethers } from "hardhat";

async function main() {
	const Only = await ethers.getContractFactory("Only");
	const only = await Only.attach("0xfeC24eA022A9eC92b6dBe306Dfc674D5f120A786");

	// await only.mint(1, {value : ethers.utils.parseEther("0.001")});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
