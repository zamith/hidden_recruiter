import { useContract, useProvider, useSigner } from "wagmi";

import GameContract from "../../artifacts/src/contracts/Game.sol/Game.json";
const GAME_ADDRESS = "0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9";

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
