pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/poseidon.circom";

template AgentReveal() {
    // Public inputs
    signal input askPosition[2];
    signal input revealedNumber;
    signal input hashedPosition;

    // Private inputs
    signal input privSalt;

    component hash = Poseidon(3);
    hash.inputs[0] <== askPosition[0];
    hash.inputs[1] <== askPosition[1];
    hash.inputs[2] <== privSalt;

    hash.out === hashedPosition;
}

component main {public [askPosition, revealedNumber, hashedPosition]} = AgentReveal();
