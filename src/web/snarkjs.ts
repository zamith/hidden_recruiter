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

export async function askNoMatchCalldata(
  askPositions,
  hashedPositions,
  privSalt
) {
  const input = {
    askPositions: askPositions,
    hashedPositions: hashedPositions,
    privSalt: privSalt,
  };

  let dataResult;

  try {
    dataResult = await exportCallDataGroth16(
      input,
      "/AgentAskNoMatch/AgentAskNoMatch.wasm",
      "/AgentAskNoMatch/final.zkey"
    );
  } catch (error) {
    console.log(error);
  }

  return dataResult;
}

export async function askMatchCalldata(
  askPositions,
  revealedPosition,
  hashedPositions,
  privSalt
) {
  const input = {
    askPositions: askPositions,
    revealedPosition: revealedPosition,
    hashedPositions: hashedPositions,
    privSalt: privSalt,
  };

  let dataResult;

  try {
    dataResult = await exportCallDataGroth16(
      input,
      "/AgentAsk/AgentAsk.wasm",
      "/AgentAsk/final.zkey"
    );
  } catch (error) {
    console.log(error);
  }

  return dataResult;
}

export async function askRevealCalldata(
  askPosition,
  revealedNumber,
  hashedPosition,
  privSalt
) {
  const input = {
    askPosition: askPosition,
    revealedNumber: revealedNumber,
    hashedPosition: hashedPosition,
    privSalt: privSalt,
  };

  let dataResult;

  try {
    dataResult = await exportCallDataGroth16(
      input,
      "/AgentReveal/AgentReveal.wasm",
      "/AgentReveal/final.zkey"
    );
  } catch (error) {
    console.log(error);
  }

  return dataResult;
}

export async function askCaptureCalldata(
  askPosition,
  hashedCurrentPosition,
  privSalt
) {
  const input = {
    askPosition: askPosition,
    hashedCurrentPosition: hashedCurrentPosition,
    privSalt: privSalt,
  };
  console.log(input);

  let dataResult;

  try {
    dataResult = await exportCallDataGroth16(
      input,
      "/AgentCapture/AgentCapture.wasm",
      "/AgentCapture/final.zkey"
    );
    console.log(dataResult);
  } catch (error) {
    console.log(error);
  }

  return dataResult;
}
