pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template RecruiterMove() {
    // Public inputs
    signal input oldPositionHash;
    signal input saltHash;

    // Private inputs
    signal input currentPosition[2];
    signal input newPosition[2];
    // 0 = up, 1 = right, 2 = down, 3 = left
    signal input moveDirection;
    signal input privSalt;

    // Output
    signal output updatedSaltHash;
    signal output newPositionHash;

    component hash[3];
    // Check salt hasn't been tampered with
    hash[0] = Poseidon(1);
    hash[0].inputs[0] <== privSalt;

    saltHash === hash[0].out;
    updatedSaltHash <== hash[0].out;

    // Check the old move is correct
    hash[1] = Poseidon(3);
    hash[1].inputs[0] <== currentPosition[0];
    hash[1].inputs[1] <== currentPosition[1];
    hash[1].inputs[2] <== privSalt;

    oldPositionHash === hash[1].out;

    component upperBounds[2];
    component lowerBounds[2];
    // Check x value is within bounds
    upperBounds[0] = LessEqThan(4);
    upperBounds[0].in[0] <== newPosition[0];
    upperBounds[0].in[1] <== 5;
    lowerBounds[0] = GreaterEqThan(4);
    lowerBounds[0].in[0] <== newPosition[0];
    lowerBounds[0].in[1] <== 0;

    // Check y value is within bounds
    upperBounds[1] = LessEqThan(4);
    upperBounds[1].in[0] <== newPosition[1];
    upperBounds[1].in[1] <== 6;
    lowerBounds[1] = GreaterEqThan(4);
    lowerBounds[1].in[0] <== newPosition[1];
    lowerBounds[1].in[1] <== 0;

    upperBounds[0].out + upperBounds[1].out + lowerBounds[0].out + lowerBounds[1].out === 4;

    component directions[4];
    for(var i = 0; i < 4; i++) {
      directions[i] = IsEqual();
      directions[i].in[0] <== moveDirection;
      directions[i].in[1] <== i;
    }

    // Check they actually moved
    directions[0].out + directions[1].out + directions[2].out + directions[3].out === 1;

    // Check Orthogonal move
    currentPosition[0] + directions[1].out - directions[3].out === newPosition[0];
    currentPosition[1] + directions[0].out - directions[2].out === newPosition[1];

    // Calculate the new hash
    hash[2] = Poseidon(3);
    hash[2].inputs[0] <== newPosition[0];
    hash[2].inputs[1] <== newPosition[1];
    hash[2].inputs[2] <== privSalt;

    newPositionHash <== hash[2].out;
}

component main {public [oldPositionHash, saltHash]} = RecruiterMove();
