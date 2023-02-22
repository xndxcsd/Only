import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/98f40e2ad5f84ea982aa05d0ae4d0b42`,
      accounts: ["d3db334230122de72d9c059bca001a0cfcc2bcf4270a823690483f78afd99c74"]
    }
  }
};

export default config;
