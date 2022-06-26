//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
library AgentAskPairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract AgentAskVerifier {
    using AgentAskPairing for *;
    struct VerifyingKey {
        AgentAskPairing.G1Point alfa1;
        AgentAskPairing.G2Point beta2;
        AgentAskPairing.G2Point gamma2;
        AgentAskPairing.G2Point delta2;
        AgentAskPairing.G1Point[] IC;
    }
    struct Proof {
        AgentAskPairing.G1Point A;
        AgentAskPairing.G2Point B;
        AgentAskPairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = AgentAskPairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = AgentAskPairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = AgentAskPairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = AgentAskPairing.G2Point(
            [4035688392466649593203179607642076070348662198531664839446028293647104184809,
             12280644079571793207583303377299636030712664436932482784624201965656121863364],
            [1327049537930850810473210084147544885843246320178052569248236100186927076194,
             11689711225767653841052959823009033573304189450760693769634405887403417714517]
        );
        vk.IC = new AgentAskPairing.G1Point[](28);
        
        vk.IC[0] = AgentAskPairing.G1Point( 
            74336502692255466294661592998580657339151198538868358622910125946123882320,
            12908810848233602898550946749129433478563393753707194610547904054388980316799
        );                                      
        
        vk.IC[1] = AgentAskPairing.G1Point( 
            12755024568427235014156802057582945882586109875972977342765389813101402706032,
            17452204372832008950498629634158847351915079656483992714302822358374935613791
        );                                      
        
        vk.IC[2] = AgentAskPairing.G1Point( 
            20997163690328062997230439105572011263423151215093053731593810211208029806254,
            8994342492624933862118211928936834328306873906023388913259552622921676788741
        );                                      
        
        vk.IC[3] = AgentAskPairing.G1Point( 
            8163079567504846359452644254147742034433704425741531340289430087811918841274,
            9816314712415609330482795090549954582544228538300584672045085230714318961731
        );                                      
        
        vk.IC[4] = AgentAskPairing.G1Point( 
            12371266189670589745733941531179433821033224745804923964438621500704332535432,
            5119991963923060411466957853373761169511768800818406073915579857639877950741
        );                                      
        
        vk.IC[5] = AgentAskPairing.G1Point( 
            18459252800486016939644342102043722408850763781307530728146109795470615792405,
            16808691235477711779140322906115203478417816761396495840269099044670929877860
        );                                      
        
        vk.IC[6] = AgentAskPairing.G1Point( 
            4300476559796633344023754872160453839908723256250966494625595836409665581551,
            3426769390346884076497065210778077687446178610487038545298994808525472040333
        );                                      
        
        vk.IC[7] = AgentAskPairing.G1Point( 
            12805128497430272915388150511927423109432462364048790960732102947273325065626,
            5484640158509920373571973646550610448022258260489773150308990314395718636372
        );                                      
        
        vk.IC[8] = AgentAskPairing.G1Point( 
            3751753889215589953732507207932507559608268550930803251269138946657289780363,
            12757037917211411868400183258056385412740471918364312882068898377969335651714
        );                                      
        
        vk.IC[9] = AgentAskPairing.G1Point( 
            14362691845890493078933202583125745690808820588821460327842362704195229778234,
            14298645011130232262020177807356750778128125146692472843103369214073234678248
        );                                      
        
        vk.IC[10] = AgentAskPairing.G1Point( 
            14484585236886494342536935882205768629217811399180242501837358194124239487928,
            5084873027452839388083999492132257801196304780336718788094744214181021116251
        );                                      
        
        vk.IC[11] = AgentAskPairing.G1Point( 
            11189901496066437135537105665707769990636614151440857090671990896418401240631,
            2189534960197024200366353020647127477951701794677996737665739818654344266685
        );                                      
        
        vk.IC[12] = AgentAskPairing.G1Point( 
            11689781521607917708256212693982135243389587330084334093233015164517407775081,
            21141623114483819378216643040331154755399659909938730396376534554121949987448
        );                                      
        
        vk.IC[13] = AgentAskPairing.G1Point( 
            8638953690868940890974068249321018309537719678898154069916938638179659522662,
            15653615658020748394579296767504339314217306066128894387536464302993947400948
        );                                      
        
        vk.IC[14] = AgentAskPairing.G1Point( 
            1016426233223707174444379643273581435125524289082567617500058431902172191817,
            19251751051527287446731369341775545185096872143672907525580678622389257192449
        );                                      
        
        vk.IC[15] = AgentAskPairing.G1Point( 
            16906030478352664170372347981002319293613344283842595273984240302562293130047,
            20322502889285257927486202011149930004739112241443781398612373026601022542445
        );                                      
        
        vk.IC[16] = AgentAskPairing.G1Point( 
            17308787933743935671797501697591949890130460285283681680418696901490810977599,
            4742385520323032309854301919265094565784284867261712593696522905979418110578
        );                                      
        
        vk.IC[17] = AgentAskPairing.G1Point( 
            20518049895764615832704470230204937241683276637179163779425341639968162762675,
            14049256875609318930226887511819539535672638626231764193154153408934426778442
        );                                      
        
        vk.IC[18] = AgentAskPairing.G1Point( 
            550399509918075915367327649342275938648109208246616823755832418092756054093,
            21089120339776912359973529838932384371431882314525670568420480379518534080105
        );                                      
        
        vk.IC[19] = AgentAskPairing.G1Point( 
            16355748262190476337389462455387605981040164529646323648537068888234766117466,
            2801537996524698898970537401751603941571833418254949761028707618692805633037
        );                                      
        
        vk.IC[20] = AgentAskPairing.G1Point( 
            10913977565844044526419836041069011838038188716809741378615076250235107372779,
            21849533028521565805844870283786492556159800148597241944836236427248365206656
        );                                      
        
        vk.IC[21] = AgentAskPairing.G1Point( 
            21573525766701412548293568433932260883035005365732880375394924827010491535658,
            10556566929434599442320969544863936366794080282444463575670297771865145090726
        );                                      
        
        vk.IC[22] = AgentAskPairing.G1Point( 
            20118185649557869553465967400974950309340436508275227013452933839923841322216,
            16075129787521081368777522806569440688947804391085933096381197855126209752130
        );                                      
        
        vk.IC[23] = AgentAskPairing.G1Point( 
            18727627108998568224011008934998622820503869035335235412462375604228489494615,
            2192180938244742840005268353128898549712072516973851270779219979987312523384
        );                                      
        
        vk.IC[24] = AgentAskPairing.G1Point( 
            12164656336306241222188008622735629748964775796437536608523086780359684451492,
            18132111581397625368673858191632950725124567123181750802090401876471005263012
        );                                      
        
        vk.IC[25] = AgentAskPairing.G1Point( 
            6310952248493925835470291361804346970818559276260094592464913211908108272894,
            5702025173519755343052471441028892586383767277523570913005377047592090201988
        );                                      
        
        vk.IC[26] = AgentAskPairing.G1Point( 
            16835773655315003805852004357307894639085997515553539396967873639642403258705,
            19009193176380535409605162710884676315070633128209665357512554964883714542164
        );                                      
        
        vk.IC[27] = AgentAskPairing.G1Point( 
            19145420444583593098882789570720116010112114099584928342908233286792740477141,
            10769106551725159951263050194096593229571514049912499275631447968067915573580
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        AgentAskPairing.G1Point memory vk_x = AgentAskPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = AgentAskPairing.addition(vk_x, AgentAskPairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = AgentAskPairing.addition(vk_x, vk.IC[0]);
        if (!AgentAskPairing.pairingProd4(
            AgentAskPairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[27] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = AgentAskPairing.G1Point(a[0], a[1]);
        proof.B = AgentAskPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = AgentAskPairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
