import { exportCallDataGroth16 } from "./snarkjsZkproof";

export async function firstMoveCalldata(newPosition, privSalt) {
  const input = {
    newPosition: newPosition,
    privSalt: privSalt,
  };

  let dataResult;

  try {
    dataResult = await exportCallDataGroth16(
      input,
      "/StartingMove/StartingMove.wasm",
      "/StartingMove/final.zkey"
    );
  } catch (error) {
    console.log(error);
  }

  return dataResult;
}
