import { useAccount, useContractWrite, useContractRead } from "wagmi";
import { constants } from "ethers";
import { useEffect } from "react";

import { gameContractInfoNoSigner, gameContractInfo } from "../contracts";
import { useIsSSR, useSSRLocalStorage } from "../utils";
import GameContract from "../../../artifacts/src/contracts/Game.sol/Game.json";

function GameControls({ gameId }) {
  const [role, setRole] = useSSRLocalStorage("role", undefined);
  const { data: account } = useAccount();
  const isSSR = useIsSSR();
  const setRecruiter = useContractWrite(gameContractInfo(), "setRecruiter", {
    args: [gameId, account?.address],
    onSuccess(data) {
      setRole("recruiter");
    },
  });
  const addAgent = useContractWrite(gameContractInfo(), "addAgent", {
    args: [gameId, account?.address],
    onSuccess(data) {
      setRole("agent");
      getRecruiter.refetch();
    },
  });
  const getRecruiter = useContractRead(
    gameContractInfoNoSigner(),
    "recruiters",
    {
      args: [gameId],
      enabled: false,
    }
  );
  const agentsNeeded = useContractRead(
    gameContractInfoNoSigner(),
    "agentsNeeded",
    {
      args: [gameId],
      enabled: false,
    }
  );

  function recruiterIsSet() {
    return (
      getRecruiter.isFetched && getRecruiter.data !== constants.AddressZero
    );
  }

  function isRecruiter() {
    return getRecruiter.isFetched && getRecruiter.data === account.address;
  }

  function isAgent() {
    // return getRecruiter.isFetched && getRecruiter.data === account.address;
  }

  function needsAgents() {
    if (agentsNeeded.isFetched) {
      return agentsNeeded.data;
    }

    return false;
  }

  useEffect(() => {
    if (gameId) {
      getRecruiter.refetch();
      agentsNeeded.refetch();
    }
  }, [gameId]);

  if (isSSR) {
    return;
  }

  return (
    <div>
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

      {!isRecruiter() && needsAgents() && (
        <div>
          <button
            disabled={addAgent.isLoading}
            onClick={() => addAgent.write()}
          >
            Make me an agent
          </button>
        </div>
      )}
    </div>
  );
}

export default GameControls;
