import chai, { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);

import { Fr, testCircuit } from "./utils";

describe("RecruiterMove", function () {
  this.timeout(100000000);

  it("is true if the move is valid", async () => {
    const oldPositionHash = Fr.e(
      "19320191077368389061484541147293851813695633683046981399108678313582319073963"
    );
    const saltHash = Fr.e(
      "8016425014317990530442927998422967325567423100823384616572282301216804908444"
    );

    const [_valid, updatedSaltHash, newPositionHash] = await testCircuit(
      "src/circuits/RecruiterMove.circom",
      {
        currentPosition: [2, 1],
        newPosition: [3, 1],
        moveDirection: 1,
        oldPositionHash: oldPositionHash,
        saltHash: saltHash,
        privSalt: Fr.e("54325666"),
      }
    );

    expect(updatedSaltHash).to.frEq(saltHash);
    expect(newPositionHash).to.frEq(
      Fr.e(
        "16804455789330227375872268341739782469247210261748214837473768853964358120025"
      )
    );
  });

  it("is false if new position is out of bounds", async () => {
    const oldPositionHash = Fr.e(
      "19320191077368389061484541147293851813695633683046981399108678313582319073963"
    );
    const saltHash = Fr.e(
      "8016425014317990530442927998422967325567423100823384616572282301216804908444"
    );

    expect(
      testCircuit("src/circuits/RecruiterMove.circom", {
        currentPosition: [2, 1],
        newPosition: [7, 1],
        moveDirection: 1,
        oldPositionHash: oldPositionHash,
        saltHash: saltHash,
        privSalt: Fr.e("54325666"),
      })
    ).to.eventually.be.rejectedWith(Error, /Assert Error/);
  });

  it("is false if new position is not orthogonal", async () => {
    const oldPositionHash = Fr.e(
      "19320191077368389061484541147293851813695633683046981399108678313582319073963"
    );
    const saltHash = Fr.e(
      "8016425014317990530442927998422967325567423100823384616572282301216804908444"
    );

    expect(
      testCircuit("src/circuits/RecruiterMove.circom", {
        currentPosition: [2, 1],
        newPosition: [3, 2],
        moveDirection: 1,
        oldPositionHash: oldPositionHash,
        saltHash: saltHash,
        privSalt: Fr.e("54325666"),
      })
    ).to.eventually.be.rejectedWith(Error, /Assert Error/);
  });

  it("is false if new position is not in the given direction", async () => {
    const oldPositionHash = Fr.e(
      "19320191077368389061484541147293851813695633683046981399108678313582319073963"
    );
    const saltHash = Fr.e(
      "8016425014317990530442927998422967325567423100823384616572282301216804908444"
    );

    expect(
      testCircuit("src/circuits/RecruiterMove.circom", {
        currentPosition: [2, 1],
        newPosition: [1, 1],
        moveDirection: 1,
        oldPositionHash: oldPositionHash,
        saltHash: saltHash,
        privSalt: Fr.e("54325666"),
      })
    ).to.eventually.be.rejectedWith(Error, /Assert Error/);
  });
});
