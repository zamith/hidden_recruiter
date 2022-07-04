pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/gates.circom";

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
