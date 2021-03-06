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
library AgentAskNoMatchPairing {
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
contract AgentAskNoMatchVerifier {
    using AgentAskNoMatchPairing for *;
    struct VerifyingKey {
        AgentAskNoMatchPairing.G1Point alfa1;
        AgentAskNoMatchPairing.G2Point beta2;
        AgentAskNoMatchPairing.G2Point gamma2;
        AgentAskNoMatchPairing.G2Point delta2;
        AgentAskNoMatchPairing.G1Point[] IC;
    }
    struct Proof {
        AgentAskNoMatchPairing.G1Point A;
        AgentAskNoMatchPairing.G2Point B;
        AgentAskNoMatchPairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = AgentAskNoMatchPairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = AgentAskNoMatchPairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = AgentAskNoMatchPairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = AgentAskNoMatchPairing.G2Point(
            [9704995549808679320141439752631028527017267245325882023545019616577651938236,
             13961396681095585243449670744378218019766785515326936097958668804675230263820],
            [16041501539051149944998993004958338164057355732512710647322868290754873375126,
             6318553274660820206380641756945833069846438041792613669905612138538268548297]
        );
        vk.IC = new AgentAskNoMatchPairing.G1Point[](26);
        
        vk.IC[0] = AgentAskNoMatchPairing.G1Point( 
            6758037363887589750116392482821784563381082624045606688337914413042507624361,
            3713333959278875171233560665307608286770925165007974859133236666122408048959
        );                                      
        
        vk.IC[1] = AgentAskNoMatchPairing.G1Point( 
            20350487190327624771769324617537864132197432088398420833166428272593004966706,
            19567532557230965127633431495713871443343579928279359479852176509782337238796
        );                                      
        
        vk.IC[2] = AgentAskNoMatchPairing.G1Point( 
            13920074326573395014900319637350889802371225021781752708844553152612680051192,
            18282266878328706911568728694454568970200008955631861824750725517603320826153
        );                                      
        
        vk.IC[3] = AgentAskNoMatchPairing.G1Point( 
            3873358459030265882485341043871835606351058214958973386693793588359218310803,
            10553205812947746505258976323441661972283191151859488432578673525918085447418
        );                                      
        
        vk.IC[4] = AgentAskNoMatchPairing.G1Point( 
            4693994290135251695474305002256456920819641994616475379989575253020816585261,
            2811454614577611405438047954894206672318448208061061551081363672782806523100
        );                                      
        
        vk.IC[5] = AgentAskNoMatchPairing.G1Point( 
            5037670029745779899980936605564582954286139152815376775609516367571345468048,
            16402380655791596569343908680589357164710459123962771367999344973132168222224
        );                                      
        
        vk.IC[6] = AgentAskNoMatchPairing.G1Point( 
            6303744466520859640457882999402522680776154905897437974341699413331455562922,
            141035938648732690634666058648227145372171197857960417657511033400010165856
        );                                      
        
        vk.IC[7] = AgentAskNoMatchPairing.G1Point( 
            21189842854105632274431847873928458797451945719254678542928130500260016144484,
            19330709199006496233492748884988417570336908964694691109271211937320795060893
        );                                      
        
        vk.IC[8] = AgentAskNoMatchPairing.G1Point( 
            17963382445745263035732943700721960162627671373974520848099228724663939046977,
            7816580551327395729011440645258171000799430874616296503356219976228334293960
        );                                      
        
        vk.IC[9] = AgentAskNoMatchPairing.G1Point( 
            21531931171790732899897468781407261466180707432491205260550973865175478618153,
            5225420952398272570429750441510555112395147883880429243630205099483486177322
        );                                      
        
        vk.IC[10] = AgentAskNoMatchPairing.G1Point( 
            20586585400912375580908674980144389287578550832517064233762915489053243796374,
            5705443776655120925569290851168518645916294985168250835707618752769461805061
        );                                      
        
        vk.IC[11] = AgentAskNoMatchPairing.G1Point( 
            9106998902928514511748425785308568979137317522568703445599079680891831223580,
            13558043101407565700167621609557821829458035382876097367977215497908529939246
        );                                      
        
        vk.IC[12] = AgentAskNoMatchPairing.G1Point( 
            11840181013764717453211917547636049690307735719604957167591253105761766204293,
            16067789694831261298473624515547983295139993141102278525402645763280286961925
        );                                      
        
        vk.IC[13] = AgentAskNoMatchPairing.G1Point( 
            12707180064283522260187710316585076317309527805952430498333796569278601714098,
            6356003114793633737975355181283735142309397091063603555166575600386452709530
        );                                      
        
        vk.IC[14] = AgentAskNoMatchPairing.G1Point( 
            19732524442386137937076621878470785287496925613721106364026149809821262346890,
            9578619654665035942928564072004367971234872138534247846048563470661196289365
        );                                      
        
        vk.IC[15] = AgentAskNoMatchPairing.G1Point( 
            13107137894102137542133739479237865960140690775805971648215014343437989237149,
            20370509458331590949494007908724336468761051023349380166915528812207298328092
        );                                      
        
        vk.IC[16] = AgentAskNoMatchPairing.G1Point( 
            11709204492088618094786257704772506900084699865251239823663374661166641781797,
            7458982350290454067718878073518020306433537438419972037540093385019298933393
        );                                      
        
        vk.IC[17] = AgentAskNoMatchPairing.G1Point( 
            5389960378625597696519342558843331597690034744550824310842538136227230510636,
            13165908885191868621683060658026307217910712736917769020609768791163141967550
        );                                      
        
        vk.IC[18] = AgentAskNoMatchPairing.G1Point( 
            11342277567062365743622106940400090794830913506143501500288878868931370686183,
            21554808644547557206876596212844691594041768873197278480665765045347010975706
        );                                      
        
        vk.IC[19] = AgentAskNoMatchPairing.G1Point( 
            5755116969641716435213005660907592106329238621059026938561492591518870337127,
            15521620776732722278186524732882285506217348735309718176911294609007961394257
        );                                      
        
        vk.IC[20] = AgentAskNoMatchPairing.G1Point( 
            13904155807331582053496495084492315238100281110798976967998933348246203202624,
            10072348101840019774900001283015837028615498013918311542131346468084285916496
        );                                      
        
        vk.IC[21] = AgentAskNoMatchPairing.G1Point( 
            6846728559722271143152561532054145238938573422181663770709474726976240071644,
            6128286910528438333367184560068220302939162989854577307422130273142664815007
        );                                      
        
        vk.IC[22] = AgentAskNoMatchPairing.G1Point( 
            5211146722761363388408090827157682215112931272876048516661869956028996488406,
            5215905164505830431695671627839769904205609757212899362460595299410102691982
        );                                      
        
        vk.IC[23] = AgentAskNoMatchPairing.G1Point( 
            6095069198706130378264706932222082864236392414536569170866402356214286045034,
            758340750694071991872457009729447537515407171971539761080173696160204591984
        );                                      
        
        vk.IC[24] = AgentAskNoMatchPairing.G1Point( 
            4267418675322765027430155120477207414403896816258286135125818581338490524684,
            9291897149818170503226540894081306862736054446788199300294622098770439047844
        );                                      
        
        vk.IC[25] = AgentAskNoMatchPairing.G1Point( 
            14250416125736645844028746455655841737799414161673509196339406283171687649364,
            14351811574680335335125276473668879943273745784801713011503320143068974024485
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        AgentAskNoMatchPairing.G1Point memory vk_x = AgentAskNoMatchPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = AgentAskNoMatchPairing.addition(vk_x, AgentAskNoMatchPairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = AgentAskNoMatchPairing.addition(vk_x, vk.IC[0]);
        if (!AgentAskNoMatchPairing.pairingProd4(
            AgentAskNoMatchPairing.negate(proof.A), proof.B,
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
            uint[25] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = AgentAskNoMatchPairing.G1Point(a[0], a[1]);
        proof.B = AgentAskNoMatchPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = AgentAskNoMatchPairing.G1Point(c[0], c[1]);
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
