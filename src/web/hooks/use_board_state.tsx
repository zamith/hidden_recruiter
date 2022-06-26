import { useEffect, useState } from "react";
import { useContractWrite, useContractRead } from "wagmi";
import random from "random-bigint";

import { useSSRLocalStorage } from "../utils";
import { firstMoveCalldata } from "../snarkjs";
import { gameContractInfoNoSigner, gameContractInfo } from "../contracts";

export function useBoardState(gameId) {
  const [role, setRole] = useSSRLocalStorage("role", undefined);
  const [privSalt, setPrivSalt] = useSSRLocalStorage("privSalt", undefined);
  const [moveHash, setMoveHash] = useState(undefined);
  const [calldata, setCalldata] = useState([]);
  const numberOfRecruiterMoves = useContractRead(
    gameContractInfoNoSigner(),
    "numberOfRecruiterMoves",
    {
      args: [gameId],
      enabled: false,
    }
  );
  const firstMove = useContractWrite(gameContractInfo(), "recruiterFirstMove", {
    args: [
      gameId,
      moveHash,
      calldata[0],
      calldata[1],
      calldata[2],
      calldata[3],
    ],
  });

  useEffect(() => {
    numberOfRecruiterMoves.refetch();
  }, [gameId]);

  async function move(x, y) {
    console.log("move", x, y);
    console.log(BigInt(numberOfRecruiterMoves.data));
    if (role === "recruiter") {
      if (BigInt(numberOfRecruiterMoves.data) === BigInt(0)) {
        console.log(await firstMoveCalldata([x, y], random(128)));
      }

      if (numberOfRecruiterMoves.data < 5) {
        // initial moves
      }
      // other moves
    } else if (role === "agent") {
      // other moves
    } else {
      console.log("no role");
    }
  }

  return {
    move,
  };
}
