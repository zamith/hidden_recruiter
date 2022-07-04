pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "./MultiOr.circom";

template AgentCapture() {
    // Public inputs
    signal input askPosition[2];
    signal input hashedCurrentPosition;

    // Private inputs
    signal input privSalt;

    signal output captured;

    component hash = Poseidon(3);
    hash.inputs[0] <== askPosition[0];
    hash.inputs[1] <== askPosition[1];
    hash.inputs[2] <== privSalt;

    component isCaptured = IsEqual();
    isCaptured.in[0] <== hash.out;
    isCaptured.in[1] <== hashedCurrentPosition;

    captured <== isCaptured.out;
}

component main {public [askPosition, hashedCurrentPosition]} = AgentCapture();
