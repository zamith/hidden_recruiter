import "@nomiclabs/hardhat-ethers";
import "./tasks/deploy";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
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
  },
};
