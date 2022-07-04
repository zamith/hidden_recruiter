import {
  useAccount,
  useContractWrite,
  useContractRead,
  useContractEvent,
} from "wagmi";
import { constants } from "ethers";
import { useEffect, useState } from "react";

import {
  useGameContract,
  gameContractInfoNoSigner,
  gameContractInfo,
} from "../contracts";
import { useIsSSR, useSSRLocalStorage } from "../utils";
import GameContract from "../../../artifacts/src/contracts/Game.sol/Game.json";
import { useBoardState } from "../hooks/use_board_state";
import styles from "../styles/GameControls.module.css";

function GameControls({ gameId }) {
  const boardState = useBoardState(gameId);
  const contract = useGameContract();
  const [role, setRole] = useSSRLocalStorage("role", undefined);
  const [agentLocation, setAgentLocation] = useSSRLocalStorage(
    "agentLocation",
    undefined
  );
  const { data: account } = useAccount();
  const isSSR = useIsSSR();
  const setRecruiter = useContractWrite(gameContractInfo(), "setRecruiter", {
    args: [gameId, account?.address],
    onSuccess(data) {
      setRole("recruiter");
      getRecruiter.refetch();
    },
  });
  const addAgent = useContractWrite(gameContractInfo(), "addAgent", {
    args: [gameId, account?.address],
    onSuccess(data) {
      setRole("agent");
      setAgentLocation(getAgentPosition.data);
      agentsNeeded.refetch();
    },
  });
  const startGame = useContractWrite(gameContractInfo(), "startGame", {
    args: [gameId],
    onSuccess(data) {
      gameStatus.refetch();
    },
  });
  const agentAskNotify = useContractWrite(
    gameContractInfo(),
    "agentAskNotify",
    {
      args: [gameId, agentLocation],
    }
  );
  const agentCaptureNotify = useContractWrite(
    gameContractInfo(),
    "agentCaptureNotify",
    {
      args: [gameId, agentLocation],
    }
  );
  const agentRevealNotify = useContractWrite(
    gameContractInfo(),
    "agentRevealNotify",
    {
      args: [gameId, agentLocation],
    }
  );
  const getRecruiter = useContractRead(
    gameContractInfoNoSigner(),
    "recruiters",
    {
      args: [gameId],
    }
  );
  const getAgentPosition = useContractRead(
    gameContractInfoNoSigner(),
    "agentPositions",
    {
      args: [gameId, account?.address],
    }
  );
  const agentsNeeded = useContractRead(
    gameContractInfoNoSigner(),
    "agentsNeeded",
    {
      args: [gameId],
    }
  );
  const gameStatus = useContractRead(
    gameContractInfoNoSigner(),
    "gameStatuses",
    {
      args: [gameId],
    }
  );
  const round = useContractRead(gameContractInfoNoSigner(), "rounds", {
    args: [gameId],
  });

  useContractEvent(gameContractInfoNoSigner(), "RecruiterMoved", (event) => {
    gameStatus.refetch();
    round.refetch();
  });

  useContractEvent(gameContractInfoNoSigner(), "AgentMoved", (event) => {
    gameStatus.refetch();
    round.refetch();
  });

  function recruiterIsSet() {
    return (
      getRecruiter.isFetched && getRecruiter.data !== constants.AddressZero
    );
  }

  function isRecruiter() {
    return role === "recruiter";
  }

  function isAgent() {
    return role === "agent";
  }

  function needsAgents() {
    if (agentsNeeded.isFetched) {
      return agentsNeeded.data;
    }

    return false;
  }

  if (isSSR || !gameId) {
    return;
  }

  async function handleNoMatch() {
    await boardState.askNoMatch(ask);
  }

  function renderRound() {
    if (!gameStatus.isSuccess && !round.data) {
      return;
    }

    if (gameStatus.data === 2) {
      if (!isRecruiter()) {
        return <p>Recruiter planning initial moves</p>;
      } else {
        return <p>Plan your 5 initial moves</p>;
      }
    }

    if (gameStatus.data === 4) {
      return <p>Recruiter won!</p>;
    }

    if (gameStatus.data === 5) {
      return <p>Agents won!</p>;
    }

    if (gameStatus.data > 1) {
      return (
        <div>
          <p>Round {round.data.number.toString()}</p>
          {round.data.recruiterMoved ? (
            <div>
              <p>Agents move</p>
              {isAgent() && (
                <div className={styles.agentActions}>
                  <button onClick={() => agentAskNotify.write()}>
                    Ask for feature
                  </button>
                  <button onClick={() => agentCaptureNotify.write()}>
                    Capture
                  </button>
                  <button onClick={() => agentRevealNotify.write()}>
                    Reveal
                  </button>
                </div>
              )}
            </div>
          ) : (
            <div>
              <p>Recruiter move</p>
            </div>
          )}
        </div>
      );
    }
  }

  function renderRecruiterActions() {
    if (boardState.answerAsk) {
      return (
        <button onClick={() => boardState.handleAgentAsked()}>
          Answer Agent Ask
        </button>
      );
    }

    if (boardState.answerCapture) {
      return (
        <button onClick={() => boardState.handleAgentCaptured()}>
          Answer Agent Capture
        </button>
      );
    }

    if (boardState.answerReveal) {
      return (
        <button onClick={() => boardState.handleAgentRevealed()}>
          Answer Agent Reveal
        </button>
      );
    }
  }

  return (
    <div>
      {renderRound()}

      {isRecruiter() && renderRecruiterActions()}

      {!recruiterIsSet() && (
        <div>
          <button
            disabled={setRecruiter.isLoading}
            onClick={() => setRecruiter.write()}
          >
            Make me the recruiter
          </button>
        </div>
      )}

      {!isRecruiter() && !isAgent() && needsAgents() && (
        <div>
          <button
            disabled={addAgent.isLoading}
            onClick={() => addAgent.write()}
          >
            Make me an agent
          </button>
        </div>
      )}

      {isRecruiter() && gameStatus.data === 1 && (
        <div>
          <button
            disabled={startGame.isLoading}
            onClick={() => startGame.write()}
          >
            Start Game
          </button>
        </div>
      )}
    </div>
  );
}

export default GameControls;
