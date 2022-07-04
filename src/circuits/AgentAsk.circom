pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "./MultiOr.circom";

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
