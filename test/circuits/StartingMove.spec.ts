import chai, { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);

import { Fr, testCircuit } from "./utils";

describe("StartingMove", function () {
  this.timeout(100000000);

  it("is true if the move is valid", async () => {
    const [_valid, saltHash, newPositionHash] = await testCircuit(
      "src/circuits/StartingMove.circom",
      {
        newPosition: [3, 1],
        privSalt: Fr.e("54325666"),
      }
    );

    expect(saltHash).to.frEq(
      Fr.e(
        "8016425014317990530442927998422967325567423100823384616572282301216804908444"
      )
    );
    expect(newPositionHash).to.frEq(
      Fr.e(
        "16804455789330227375872268341739782469247210261748214837473768853964358120025"
      )
    );
  });

  it("is false if new position is out of bounds", async () => {
    expect(
      testCircuit("src/circuits/StartingMove.circom", {
        newPosition: [7, 1],
        privSalt: Fr.e("54325666"),
      })
    ).to.eventually.be.rejectedWith(Error, /Assert Error/);
  });
});
