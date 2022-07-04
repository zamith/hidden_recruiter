import { useContract, useProvider, useSigner } from "wagmi";

import GameContract from "../../artifacts/src/contracts/Game.sol/Game.json";
const GAME_ADDRESS = "0x0165878A594ca255338adfa4d48449f69242Eb8F";

export function useGameContract() {
  return useContract(gameContractInfo());
}

export function gameContractInfo() {
  const { data: signer } = useSigner();
  const provider = useProvider();
  return {
    addressOrName: GAME_ADDRESS,
    contractInterface: GameContract.abi,
    signerOrProvider: signer || provider,
  };
}

export function gameContractInfoNoSigner() {
  const { data: signer } = useSigner();
  const provider = useProvider();
  return {
    addressOrName: GAME_ADDRESS,
    contractInterface: GameContract.abi,
  };
}
