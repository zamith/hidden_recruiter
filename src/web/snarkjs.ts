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

export async function recruiterMoveCalldata(
  oldPositionHash,
  privSaltHash,
  currentPosition,
  newPosition,
  moveDirection,
  privSalt
) {
  const input = {
    oldPositionHash: oldPositionHash,
    saltHash: privSaltHash,
    currentPosition: currentPosition,
    newPosition: newPosition,
    moveDirection: moveDirection,
    privSalt: privSalt,
  };

  let dataResult;

  try {
    dataResult = await exportCallDataGroth16(
      input,
      "/RecruiterMove/RecruiterMove.wasm",
      "/RecruiterMove/final.zkey"
    );
  } catch (error) {
    console.log(error);
  }

  return dataResult;
}
