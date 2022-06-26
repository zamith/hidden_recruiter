pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template StartingMove() {
    // Private inputs
    signal input newPosition[2];
    signal input privSalt;

    // Output
    signal output saltHash;
    signal output newPositionHash;

    component hash[2];
    hash[0] = Poseidon(1);
    hash[0].inputs[0] <== privSalt;

    saltHash <== hash[0].out;

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

    // Calculate the new hash
    hash[1] = Poseidon(3);
    hash[1].inputs[0] <== newPosition[0];
    hash[1].inputs[1] <== newPosition[1];
    hash[1].inputs[2] <== privSalt;

    newPositionHash <== hash[1].out;
}

component main = StartingMove();
