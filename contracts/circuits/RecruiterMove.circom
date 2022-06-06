pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimc.circom";

template RecruiterMove() {
    // Public inputs
    signal input pubMovementHash;
    // 0: up, 1: down, 2: left, 3: right
    signal input new_move;

    // Private inputs
    signal input old_moves[35][2];
    signal input updated_moves[35][2];
    signal input privSalt;

    // Output
    signal output movementHashOut;

    component hash[2];
    // Check the moves so far haven't changed
    var noMoves = 35;
    hash[0] = MultiMiMC7(noMoves * 2 + 1, 91);
    hash[0].k <== 256;
    for(var j = 0; j < noMoves; j++) {
      for(var i = 0; i < 2; i++) {
        hash[0].in[2*j+i] <== old_moves[j][i];
      }
    }
    hash[0].in[2*noMoves] <== privSalt;

    pubMovementHash === hash[0].out;

    // Check the new_move is valid
    // Check new_move is orthogonal
    // Check it does not go beyond the board
    // Check it does not go to a previously visited position

    // Calculate the new hash
    hash[1] = MultiMiMC7(noMoves * 2 + 1, 91);
    hash[1].k <== 256;
    for(var j = 0; j < noMoves; j++) {
      for(var i = 0; i < 2; i++) {
        hash[1].in[2*j+i] <== updated_moves[j][i];
      }
    }
    hash[1].in[2*noMoves] <== privSalt;

    movementHashOut <== hash[1].out;
}

component main = RecruiterMove();
