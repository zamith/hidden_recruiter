pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/gates.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MultiOR(n) {
    signal input in[n];
    signal output out;
    component or;
    component or1;
    component ors[2];

    if (n==1) {
        out <== in[0];
    } else if (n==2) {
        or1 = OR();
        or1.a <== in[0];
        or1.b <== in[1];
        out <== or1.out;
    } else {
        or = OR();
        var n1 = n\2;
        var n2 = n-n\2;
        ors[0] = MultiOR(n1);
        ors[1] = MultiOR(n2);
        var i;
        for (i=0; i<n1; i++) ors[0].in[i] <== in[i];
        for (i=0; i<n2; i++) ors[1].in[i] <== in[n1+i];
        or.a <== ors[0].out;
        or.b <== ors[1].out;
        out <== or.out;
    }
}

template AgentAsk() {
    var noMoves = 14;
    // Public inputs
    signal input askPositions[5][2];
    signal input revealedPosition[2];
    signal input hashedPositions[noMoves];

    // Private inputs
    signal input privSalt;

    signal output visited;

    // Check revealed position is one of the ask positions
    component multiOr = MultiOR(5);
    component matched[5];
    component positionsComparator[5][2];
    for(var i=0; i < 5; i++) {
      positionsComparator[i][0] = IsEqual();
      positionsComparator[i][0].in[0] <== askPositions[i][0];
      positionsComparator[i][0].in[1] <== revealedPosition[0];

      positionsComparator[i][1] = IsEqual();
      positionsComparator[i][1].in[0] <== askPositions[i][1];
      positionsComparator[i][1].in[1] <== revealedPosition[1];

      matched[i] = IsEqual();
      matched[i].in[0] <== positionsComparator[i][0].out + positionsComparator[i][1].out;
      matched[i].in[1] <== 2;

      multiOr.in[i] <== matched[i].out;
    }
    multiOr.out === 1;

    component hash = Poseidon(3);
    hash.inputs[0] <== revealedPosition[0];
    hash.inputs[1] <== revealedPosition[1];
    hash.inputs[2] <== privSalt;

    component hasVisited = MultiOR(noMoves);
    component positionsMatch[noMoves];
    for (var j=0; j < noMoves; j++) {
      positionsMatch[j] = IsEqual();
      positionsMatch[j].in[0] <== hash.out;
      positionsMatch[j].in[1] <== hashedPositions[j];

      hasVisited.in[j] <== positionsMatch[j].out;
    }

    visited <== hasVisited.out;
}

component main {public [askPositions, revealedPosition, hashedPositions]} = AgentAsk();
