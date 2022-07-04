import { useRouter } from "next/router";
import { gameContractInfo, gameContractInfoNoSigner } from "../contracts";
import { useContractWrite, useContractRead } from "wagmi";

function Game() {
  const router = useRouter();
  const { data: nextGameId } = useContractRead(
    gameContractInfoNoSigner(),
    "nextGameId"
  );
  const openGame = useContractWrite(gameContractInfo(), "openGame", {
    args: [nextGameId],
    onSuccess(data) {
      router.push(`/games/${nextGameId}`);
    },
  });

  return (
    <div>
      <button onClick={() => openGame.write()}>Create a new game</button>
    </div>
  );
}

export default Game;
