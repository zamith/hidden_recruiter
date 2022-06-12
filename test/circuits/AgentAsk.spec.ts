import { expect } from "chai";

import { Fr, testCircuit } from "./utils";

describe("AgentAsk", function () {
  this.timeout(100000000);

  it("is true if the recruiter has been to the place", async () => {
    const pubMovementHash = Fr.e(
      "12161705107552638055056582591684085142116555511696014104619902267786701619978"
    );
    const [, visited, movementHashOut] = await testCircuit(
      "src/circuits/AgentAsk.circom",
      {
        ask_position: [1, 1],
        pubMovementHash: pubMovementHash,
        moves: moves(),
        privSalt: Fr.e("54325666"),
      }
    );

    expect(visited).to.frEq(1);
    expect(movementHashOut).to.frEq(pubMovementHash);
  });

  it("is false if the recruiter has not been to the place", async () => {
    const pubMovementHash = Fr.e(
      "12161705107552638055056582591684085142116555511696014104619902267786701619978"
    );
    const [, visited, movementHashOut] = await testCircuit(
      "src/circuits/AgentAsk.circom",
      {
        ask_position: [3, 1],
        pubMovementHash: pubMovementHash,
        moves: moves(),
        privSalt: Fr.e("54325666"),
      }
    );

    expect(visited).to.frEq(0);
    expect(movementHashOut).to.frEq(pubMovementHash);
  });

  function moves() {
    return [
      [0, 0],
      [0, 1],
      [1, 1],
      [2, 1],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
      [50, 50],
    ];
  }
});
