import chai, { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);

import { Fr, testCircuit } from "./utils";

describe("RecruiterMove", function () {
  this.timeout(100000000);

  it("is true if the move is valid", async () => {
    const pubMovementHash = Fr.e(
      "14661562570220400304557756534380332684059033175579402621010282490798865787494"
    );
    const newMove = [3, 1];

    const [valid, newHash] = await testCircuit(
      "src/circuits/RecruiterMove.circom",
      {
        newMove: newMove,
        pubMovementHash: pubMovementHash,
        updatedMoves: updatedMoves(newMove),
        oldMoves: oldMoves(),
        privSalt: Fr.e("54325666"),
      }
    );

    expect(valid).to.frEq(1);
    expect(newHash).to.frEq(
      Fr.e(
        "2009700648142929371758411387655140572637421401912403447540310693356513974054"
      )
    );
  });

  it("is false if the updated moves have been tampered with", async () => {
    const pubMovementHash = Fr.e(
      "12161705107552638055056582591684085142116555511696014104619902267786701619978"
    );
    const newMove = [3, 1];

    expect(
      testCircuit("src/circuits/RecruiterMove.circom", {
        newMove: newMove,
        pubMovementHash: pubMovementHash,
        oldMoves: oldMoves(),
        updatedMoves: tamperedMoves(),
        privSalt: Fr.e("54325666"),
      })
    ).to.eventually.be.rejectedWith(Error, /Assert Error/);
  });

  function oldMoves() {
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
    ];
  }

  function updatedMoves(newMove: number[]) {
    return [
      [0, 0],
      [0, 1],
      [1, 1],
      [2, 1],
      newMove,
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

  function tamperedMoves() {
    return [
      [0, 0],
      [0, 1],
      [1, 2],
      [2, 1],
      [3, 1],
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
