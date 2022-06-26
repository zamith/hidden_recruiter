import { useEffect, useState } from "react";
import { useAccount, useContractRead } from "wagmi";
import random from "random-bigint";

import { useSSRLocalStorage } from "../utils";
import { firstMoveCalldata, recruiterMoveCalldata } from "../snarkjs";
import {
  useGameContract,
  gameContractInfoNoSigner,
  gameContractInfo,
} from "../contracts";

export function useBoardState(gameId) {
  const { data: account } = useAccount();
  const [role, _setRole] = useSSRLocalStorage("role", undefined);
  const [privSalt, setPrivSalt] = useSSRLocalStorage("privSalt", undefined);
  const [privSaltHash, setPrivSaltHash] = useSSRLocalStorage(
    "privSaltHash",
    undefined
  );
  const [recruiterMoves, setRecruiterMoves] = useSSRLocalStorage(
    "recruiterMoves",
    undefined
  );
  const [recruiterMovesHashes, setRecruiterMovesHashes] = useSSRLocalStorage(
    "recruiterMovesHashes",
    undefined
  );
  const contract = useGameContract();
  const numberOfRecruiterMoves = useContractRead(
    gameContractInfoNoSigner(),
    "numberOfRecruiterMoves",
    {
      args: [gameId],
      enabled: false,
    }
  );
  const numberOfAgents = useContractRead(
    gameContractInfoNoSigner(),
    "numberOfAgents",
    {
      args: [gameId],
      enabled: false,
    }
  );

  useEffect(() => {
    if (gameId) {
      numberOfRecruiterMoves.refetch();
      numberOfAgents.refetch();
    }
  }, [gameId]);

  function recruiterMovesToIndex() {
    return (recruiterMoves || []).reduce((acc, move, index) => {
      return { ...acc, [move]: index + 1 };
    }, {});
  }

  async function agentsAt(x, y) {
    if (!numberOfAgents.isSuccess) {
      return [];
    }

    let agents = [];
    for (let i = 0; i < numberOfAgents.data; i++) {
      const agentAddress = await contract.agents(gameId, i);
      const agentPosition = await contract.agentPositions(gameId, agentAddress);

      if (agentPosition.x == x && agentPosition.y == y) {
        agents = [...agents, agentAddress];
      }
    }

    return agents;
  }

  async function move(x, y) {
    if (role === "recruiter") {
      if (BigInt(numberOfRecruiterMoves.data) === BigInt(0)) {
        setPrivSalt(random(128));
        const calldata = await firstMoveCalldata([x, y], privSalt);
        try {
          const txn = await contract.recruiterFirstMove(
            gameId,
            calldata[3][1],
            calldata[0],
            calldata[1],
            calldata[2],
            calldata[3]
          );
          await txn.wait();
          const newRecruiterMoves = [[x, y], ...recruiterMoves];
          setRecruiterMoves(newRecruiterMoves);

          const newRecruiterMovesHashes = [
            calldata[3][1],
            ...recruiterMovesHashes,
          ];
          setPrivSaltHash(calldata[3][0]);
          setRecruiterMovesHashes(newRecruiterMovesHashes);
        } catch (e) {
          console.log("Could not verify first move", e);
        }
        return;
      }

      if (BigInt(numberOfRecruiterMoves.data) < BigInt(5)) {
        const calldata = await recruiterMoveCalldata(
          recruiterMovesHashes[0],
          privSaltHash,
          recruiterMoves[0],
          [x, y],
          moveDirection(x, y),
          privSalt
        );
        console.log(calldata);
        try {
          const txn = await contract.recruiterMoveInitial(
            gameId,
            calldata[3][1],
            calldata[0],
            calldata[1],
            calldata[2],
            calldata[3]
          );
          await txn.wait();
          const newRecruiterMoves = [[x, y], ...recruiterMoves];
          setRecruiterMoves(newRecruiterMoves);
          const newRecruiterMovesHashes = [
            calldata[3][1],
            ...recruiterMovesHashes,
          ];
          setRecruiterMovesHashes(newRecruiterMovesHashes);
        } catch (e) {
          console.log("Could not verify first move", e);
        }
        return;
      }
      // other moves
    } else if (role === "agent") {
      // other moves
    } else {
      console.log("no role");
    }
  }

  function moveDirection(x, y) {
    const [oldX, oldY] = recruiterMoves[0];

    if (oldX > x) {
      return 3;
    }
    if (oldX < x) {
      return 1;
    }
    if (oldY > y) {
      return 2;
    }
    if (oldY < y) {
      return 0;
    }

    return 0;
  }

  return {
    move,
    agentsAt,
    recruiterMovesToIndex,
  };
}
