import { ethers } from "hardhat";

async function main() {
  const Only = await ethers.getContractFactory("Only");
  const only = await Only.deploy();
  
  console.log(`only address is ${only.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
