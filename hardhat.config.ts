import * as dotenv from "dotenv";
dotenv.config();
import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";
import "./tasks/deploy";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import("hardhat/config").HardhatUserConfig
 */

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

console.log(process.env.MATIC_PRIVATE_KEY);

export default {
  solidity: "0.8.4",
  dependencyCompiler: {
    paths: [
      "build/AgentAsk/AgentAskVerifier.sol",
      "build/RecruiterMove/RecruiterMoveVerifier.sol",
      "build/StartingMove/StartingMoveVerifier.sol",
    ],
  },
  paths: {
    sources: "./src/contracts",
  },
  networks: {
    hardhat: {
      gas: 2100000,
      gasPrice: 8000000000,
      blockGasLimit: 3000000000,
    },
    harmony_devnet: {
      url: "https://api.s0.ps.hmny.io",
      accounts: [`0x${process.env.HARMONY_PRIVATE_KEY}`],
    },
    harmony_mainnet: {
      url: "https://api.harmony.one",
      accounts: [`0x${process.env.HARMONY_PRIVATE_KEY}`],
    },
    matic: {
      url: "https://polygon-rpc.com/",
      accounts: [`0x${process.env.MATIC_PRIVATE_KEY}`],
    },
  },
};
