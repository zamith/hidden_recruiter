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

    const StartingMoveVerifierContract = await ethers.getContractFactory(
      "StartingMoveVerifier"
    );
    const startingMoveVerifier = await StartingMoveVerifierContract.deploy();
    await startingMoveVerifier.deployed();
    logs &&
      console.log(
        `StartingMoveVerifier contract has been deployed to: ${startingMoveVerifier.address}`
      );

    const RecruiterMoveVerifierContract = await ethers.getContractFactory(
      "RecruiterMoveVerifier"
    );
    const recruiterMoveVerifier = await RecruiterMoveVerifierContract.deploy();
    await recruiterMoveVerifier.deployed();
    logs &&
      console.log(
        `RecruiterMoveVerifier contract has been deployed to: ${recruiterMoveVerifier.address}`
      );

    const GameContract = await ethers.getContractFactory("Game");
    const game = await GameContract.deploy(
      agentAskVerifier.address,
      startingMoveVerifier.address,
      recruiterMoveVerifier.address
    );
    await game.deployed();
    logs && console.log(`Game contract has been deployed to: ${game.address}`);

    return game;
  });
