pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "./MultiOr.circom";

template AgentAskNoMatch() {
    var noMoves = 14;
    // Public inputs
    signal input askPositions[5][2];
    signal input hashedPositions[noMoves];

    // Private inputs
    signal input privSalt;

    signal output visited;

    component hash[5];
    for(var i=0; i < 5; i++) {
      hash[i] = Poseidon(3);
      hash[i].inputs[0] <== askPositions[i][0];
      hash[i].inputs[1] <== askPositions[i][1];
      hash[i].inputs[2] <== privSalt;
    }

    component hasVisited = MultiOR(noMoves);
    component positionsMatch[noMoves][5];
    for (var j=0; j < noMoves; j++) {
      for(var i=0; i < 5; i++) {
        positionsMatch[j][i] = IsEqual();
        positionsMatch[j][i].in[0] <== hash[i].out;
        positionsMatch[j][i].in[1] <== hashedPositions[j];
      }
      hasVisited.in[j] <== positionsMatch[j][0].out +
        positionsMatch[j][1].out +
        positionsMatch[j][2].out +
        positionsMatch[j][3].out +
        positionsMatch[j][4].out;
    }

    visited <== hasVisited.out;
}

component main {public [askPositions, hashedPositions]} = AgentAskNoMatch();
