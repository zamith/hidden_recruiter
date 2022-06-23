pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/mimc.circom";

template RecruiterMove() {
    var noMoves = 14;
    var emptyMove = 50;

    // Public inputs
    signal input pubMovementHash;

    // Private inputs
    signal input newMove[2];
    signal input oldMoves[noMoves][2];
    signal input updatedMoves[noMoves][2];
    signal input privSalt;

    // Output
    signal output movementHashOut;

    component hash[2];
    // Check the moves so far haven't changed
    hash[0] = MultiMiMC7(noMoves * 2 + 1, 91);
    hash[0].k <== 256;
    for(var j = 0; j < noMoves; j++) {
      for(var i = 0; i < 2; i++) {
        hash[0].in[2*j+i] <== oldMoves[j][i];
      }
    }
    hash[0].in[2*noMoves] <== privSalt;

    pubMovementHash === hash[0].out;

    // Check new moves and old moves match
    component matcher[noMoves][2];
    var matched = 0;
    for(var j = 0; j < noMoves; j++) {
      for(var i = 0; i < 2; i++) {
        matcher[j][i] = IsEqual();
        matcher[j][i].in[0] <== updatedMoves[j][i];
        matcher[j][i].in[1] <== oldMoves[j][i];
        matched += matcher[j][i].out;
      }
    }

    // All existing positions should match on both x and y
    matched === (noMoves - 1) * 2;

    component upperBounds[2];
    component lowerBounds[2];
    // Check x value is within bounds
    upperBounds[0] = LessEqThan(4);
    upperBounds[0].in[0] <== newMove[0];
    upperBounds[0].in[1] <== 5;
    lowerBounds[0] = GreaterEqThan(4);
    lowerBounds[0].in[0] <== newMove[0];
    lowerBounds[0].in[1] <== 0;

    // Check y value is within bounds
    upperBounds[1] = LessEqThan(4);
    upperBounds[1].in[0] <== newMove[1];
    upperBounds[1].in[1] <== 6;
    lowerBounds[1] = GreaterEqThan(4);
    lowerBounds[1].in[0] <== newMove[1];
    lowerBounds[1].in[1] <== 0;

    // Calculate the new hash
    hash[1] = MultiMiMC7(noMoves * 2 + 1, 91);
    hash[1].k <== 256;
    for(var j = 0; j < noMoves; j++) {
      for(var i = 0; i < 2; i++) {
        hash[1].in[2*j+i] <== updatedMoves[j][i];
      }
    }
    hash[1].in[2*noMoves] <== privSalt;

    movementHashOut <== hash[1].out;
}

component main {public [pubMovementHash]} = RecruiterMove();
