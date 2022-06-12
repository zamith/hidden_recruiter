pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/mimc.circom";

template AgentAsk() {
    // Public inputs
    signal input ask_position[2];
    signal input pubMovementHash;

    // Private inputs
    signal input moves[35][2];
    signal input privSalt;

    // Output
    signal output visited;
    signal output movementHashOut;

    // Check the moves are valid
    var noMoves = 35;
    component hash = MultiMiMC7(noMoves * 2 + 1, 91);
    hash.k <== 256;
    for(var j = 0; j < noMoves; j++) {
      for(var i = 0; i < 2; i++) {
        hash.in[2*j+i] <== moves[j][i];
      }
    }
    hash.in[2*noMoves] <== privSalt;

    pubMovementHash === hash.out;
    movementHashOut <== hash.out;

    component visitedPosition[noMoves * 2];
    var has_visited = 0;
    for (var j=0; j < noMoves; j++) {
      visitedPosition[2*j] = IsEqual();
      visitedPosition[2*j].in[0] <== moves[j][0];
      visitedPosition[2*j].in[1] <== ask_position[0];

      visitedPosition[2*j + 1] = IsEqual();
      visitedPosition[2*j + 1].in[0] <== moves[j][1];
      visitedPosition[2*j + 1].in[1] <== ask_position[1];

      has_visited += visitedPosition[2*j].out * visitedPosition[2*j + 1].out;
    }

    component visitedCheck = IsEqual();
    visitedCheck.in[0] <-- has_visited;
    visitedCheck.in[1] <== 1;
    visited <== visitedCheck.out;
}

component main = AgentAsk();
