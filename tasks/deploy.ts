import { Contract } from "ethers";
import { task, types } from "hardhat/config";

task("deploy", "Deploy contracts")
  .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
  .setAction(async ({ logs }, { ethers }): Promise<Contract> => {
    const AgentAskVerifierContract = await ethers.getContractFactory(
      "AgentAskVerifier"
    );
    const agentAskVerifier = await AgentAskVerifierContract.deploy();

    await agentAskVerifier.deployed();

    logs &&
      console.log(
        `AgentAskVerifier contract has been deployed to: ${agentAskVerifier.address}`
      );

    const GameContract = await ethers.getContractFactory("Game");

    const game = await GameContract.deploy(agentAskVerifier.address);

    await game.deployed();

    logs && console.log(`Game contract has been deployed to: ${game.address}`);

    return game;
  });
