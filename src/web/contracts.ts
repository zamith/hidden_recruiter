import { useContract, useProvider, useSigner } from "wagmi";

import GameContract from "../../artifacts/src/contracts/Game.sol/Game.json";
const GAME_ADDRESS = "0x6AfC3d865A3e1a8Ee06C8f80AB3b0EF46c4F0ade";

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
