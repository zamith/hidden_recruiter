import { useEffect, useState } from "react";
import { useAccount, useContractRead, useContractEvent } from "wagmi";
import random from "random-bigint";

import { useSSRLocalStorage, stringifyJSON, parseJSON } from "../utils";
import {
  firstMoveCalldata,
  recruiterMoveCalldata,
  askNoMatchCalldata,
  askRevealCalldata,
  askCaptureCalldata,
  askMatchCalldata,
} from "../snarkjs";
import {
  useGameContract,
  gameContractInfoNoSigner,
  gameContractInfo,
} from "../contracts";

export function useBoardState(gameId) {
  const { data: account } = useAccount();
  const [agentPositions, setAgentPositions] = useState({});
  const [answerAsk, setAnswerAsk] = useState(false);
  const [answerCapture, setAnswerCapture] = useState(false);
  const [answerReveal, setAnswerReveal] = useState(false);
  const [winner, setWinner] = useState();
  const [role, _setRole] = useSSRLocalStorage("role", undefined);
  const [_agentLocation, setAgentLocation] = useSSRLocalStorage(
    "agentLocation",
    undefined
  );
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
    }
  );
  const numberOfAgents = useContractRead(
    gameContractInfoNoSigner(),
    "numberOfAgents",
    {
      args: [gameId],
    }
  );
  useContractEvent(gameContractInfoNoSigner(), "AgentMoved", async (event) => {
    await fetchAgentPositions();
  });

  useEffect(() => {
    if (gameId) {
      numberOfRecruiterMoves.refetch();
      numberOfAgents.refetch();
    }
  }, [gameId, recruiterMoves]);

  useEffect(() => {
    if (gameId) {
      fetchAgentPositions();
    }
  }, [gameId]);

  const hasAsk = useContractRead(gameContractInfoNoSigner(), "hasAsk", {
    args: [gameId],
  });
  const currentAsk = useContractRead(
    gameContractInfoNoSigner(),
    "currentAgentAsk",
    {
      args: [gameId],
    }
  );
  useContractEvent(gameContractInfoNoSigner(), "AgentAsked", (event) => {
    if (hasAsk.data && role === "recruiter") {
      setAnswerAsk(true);
    }
  });

  const hasCapture = useContractRead(gameContractInfoNoSigner(), "hasCapture", {
    args: [gameId],
  });
  const currentCapture = useContractRead(
    gameContractInfoNoSigner(),
    "currentAgentCapture",
    {
      args: [gameId],
    }
  );
  useContractEvent(gameContractInfoNoSigner(), "AgentCaptured", (event) => {
    if (hasCapture.data && role === "recruiter") {
      setAnswerCapture(true);
    }
  });

  const hasReveal = useContractRead(gameContractInfoNoSigner(), "hasReveal", {
    args: [gameId],
  });
  const currentReveal = useContractRead(
    gameContractInfoNoSigner(),
    "currentAgentReveal",
    {
      args: [gameId],
    }
  );
  useContractEvent(gameContractInfoNoSigner(), "AgentRevealed", (event) => {
    if (hasReveal.data && role === "recruiter") {
      setAnswerReveal(true);
    }
  });

  async function handleAgentAsked() {
    const feature = currentAsk.data;
    let featurePositions = [];
    for (let i = 0; i < 5; i++) {
      const { x, y } = await contract.features(feature, i);
      featurePositions.push(stringifyJSON([x, y]));
    }

    const matches = recruiterMoves.reduce((acc, move) => {
      if (featurePositions.includes(stringifyJSON(move))) {
        acc.push(move);
      }

      return acc;
    }, []);

    if (matches.length === 0) {
      const calldata = await askNoMatchCalldata(
        featurePositions.map((f) => parseJSON(f)),
        paddedRecruiterMovesHashes(),
        privSalt
      );
      try {
        const txn = await contract.agentAskRevealNoPosition(
          gameId,
          calldata[0],
          calldata[1],
          calldata[2],
          calldata[3]
        );
        await txn.wait();
      } catch (e) {
        console.log("Could not verify agent ask", e);
      }
    } else {
      const calldata = await askMatchCalldata(
        featurePositions.map((f) => parseJSON(f)),
        matches[0],
        paddedRecruiterMovesHashes(),
        privSalt
      );
      try {
        const txn = await contract.agentAskRevealPosition(
          gameId,
          calldata[0],
          calldata[1],
          calldata[2],
          calldata[3]
        );
        await txn.wait();
      } catch (e) {
        console.log("Could not verify agent ask", e);
      }
    }
    setAnswerAsk(false);
  }

  async function handleAgentCaptured() {
    const [x, y] = currentCapture.data;
    const calldata = await askCaptureCalldata(
      [x, y],
      recruiterMovesHashes[0],
      privSalt
    );
    try {
      const txn = await contract.agentCapture(
        gameId,
        calldata[0],
        calldata[1],
        calldata[2],
        calldata[3]
      );
      await txn.wait();
    } catch (e) {
      console.log("Could not verify agent ask", e);
    }
    setAnswerCapture(false);
  }

  async function handleAgentRevealed() {
    const [x, y] = currentReveal.data;
    const positionIndex = recruiterMoves.findIndex((move) => {
      return move[0] === x && move[1] === y;
    });
    const calldata = await askRevealCalldata(
      [x, y],
      recruiterMoves.length - positionIndex,
      recruiterMovesHashes[positionIndex],
      privSalt
    );
    try {
      const txn = await contract.agentReveal(
        gameId,
        calldata[0],
        calldata[1],
        calldata[2],
        calldata[3]
      );
      await txn.wait();
    } catch (e) {
      console.log("Could not verify agent ask", e);
    }
    setAnswerCapture(false);
  }

  function paddedRecruiterMovesHashes() {
    if (recruiterMovesHashes.length === 14) {
      return recruiterMovesHashes;
    }

    let padded = recruiterMovesHashes.slice();
    for (let i = recruiterMovesHashes.length; i < 14; i++) {
      padded.push("0");
    }
    return padded;
  }

  function recruiterMovesToIndex() {
    const moves = (recruiterMoves || []).slice().reverse();

    return moves.reduce((acc, move, index) => {
      const moveKey = JSON.stringify(move);
      return { ...acc, [moveKey]: index + 1 };
    }, {});
  }

  async function fetchAgentPositions() {
    if (!numberOfAgents.isSuccess) {
      return [];
    }

    let positions = {};
    for (let i = 0; i < numberOfAgents.data; i++) {
      const agentAddress = await contract.agents(gameId, i);
      const agentPosition = await contract.agentPositions(gameId, agentAddress);
      const serializedPosition = JSON.stringify(agentPosition);

      if (positions[serializedPosition]) {
        positions[serializedPosition].push(agentAddress);
      } else {
        positions[serializedPosition] = [agentAddress];
      }
    }

    setAgentPositions(positions);
  }

  async function move(x, y) {
    if (role === "recruiter") {
      if (BigInt(numberOfRecruiterMoves.data) === BigInt(0)) {
        const newPrivSalt = random(128);
        setPrivSalt(newPrivSalt);
        const calldata = await firstMoveCalldata([x, y], newPrivSalt);
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
          alert("Invalid move");
          console.log("Could not verify first move", e);
        }
      } else if (BigInt(numberOfRecruiterMoves.data) < BigInt(5)) {
        const calldata = await recruiterMoveCalldata(
          recruiterMovesHashes[0],
          privSaltHash,
          recruiterMoves[0],
          [x, y],
          moveDirection(x, y),
          privSalt
        );
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
          alert("Invalid move");
          console.log("Could not verify first move", e);
        }
      } else {
        const calldata = await recruiterMoveCalldata(
          recruiterMovesHashes[0],
          privSaltHash,
          recruiterMoves[0],
          [x, y],
          moveDirection(x, y),
          privSalt
        );
        try {
          const txn = await contract.recruiterMove(
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
          alert("Invalid move");
          console.log("Could not verify move", e);
        }
      }
    } else if (role === "agent") {
      try {
        await contract.agentMove(gameId, x, y);
        setAgentLocation([x, y]);
      } catch (e) {
        alert("Invalid move");
        console.log("Invalid move", e);
      }
    } else {
      console.log("no role");
    }
  }

  async function askNoMatch(feature) {
    const askPositions = [];
    for (let i = 0; i < 5; i++) {
      askPositions[i] = await contract.features(feature, i);
    }
    const hashedPositions = [];
    for (let i = 0; i < recruiterMovesHashes.length; i++) {
      hashedPositions[i] = recruiterMovesHashes[i];
    }
    for (let i = recruiterMovesHashes.length; i < 14; i++) {
      hashedPositions[i] = 0;
    }

    const calldata = await askNoMatchCalldata(
      askPositions,
      hashedPositions,
      privSalt
    );
    try {
      const txn = await contract.recruiterMove(
        gameId,
        calldata[0],
        calldata[1],
        calldata[2],
        calldata[3]
      );
      await txn.wait();
    } catch (e) {
      alert("Invalid no match");
      console.log("Could not verify no match", e);
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
    askNoMatch,
    answerAsk,
    answerCapture,
    answerReveal,
    handleAgentAsked,
    handleAgentCaptured,
    handleAgentRevealed,
    agentPositions,
    fetchAgentPositions,
    recruiterMoves,
    recruiterMovesToIndex,
    winner,
  };
}
