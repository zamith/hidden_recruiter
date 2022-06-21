// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../build/AgentAsk/AgentAskVerifier.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view returns (bool);
}

contract Game {
    IVerifier public verifier;

    enum Features {
        RED,
        BLUE,
        GREEN,
        YELLOW,
        PURPLE,
        ORANGE,
        WHITE,
        BLACK
    }

    struct Position {
        uint8 x;
        uint8 y;
    }

    // game id to moves hash
    mapping(uint256 => uint256) public movesHashes;
    // game id to agents
    mapping(uint256 => address[]) public agents;
    // features to positions with those features
    mapping(Features => Position[]) public features;

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        addFeature(Features.RED, [0, 1, 3, 4, 5], [0, 5, 4, 1, 3]);
        addFeature(Features.BLUE, [1, 4, 4, 0, 5], [0, 1, 3, 5, 6]);
        addFeature(Features.GREEN, [2, 3, 1, 3, 0], [0, 2, 3, 5, 6]);
        addFeature(Features.YELLOW, [3, 1, 3, 1, 2], [0, 1, 3, 4, 6]);
        addFeature(Features.PURPLE, [4, 2, 5, 0, 4], [0, 2, 2, 3, 5]);
        addFeature(Features.ORANGE, [5, 0, 3, 4, 1], [0, 1, 1, 5, 6]);
    }

    function startGame(
        uint256 gameId,
        address[] calldata _agents,
        uint256 movesHash
    ) public {
        require(movesHashes[gameId] == 0, "Game already started");
        movesHashes[gameId] = movesHash;

        uint256 numAgents = _agents.length;
        require(numAgents > 0 && numAgents <= 4, "Invalid number of agents");

        agents[gameId] = _agents;
    }

    function endGame(uint256 gameId) public {
        movesHashes[gameId] = 0;
        delete agents[gameId];
    }

    function agentAskProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) public {
        require(
            IVerifier(verifier).verifyProof(a, b, c, input),
            "verification error"
        );
    }

    function addFeature(
        Features feature,
        uint8[5] memory x,
        uint8[5] memory y
    ) internal {
        for (uint8 i = 0; i < 5; i++) {
            Position memory position = Position(x[i], y[i]);
            features[feature].push(position);
        }
    }
}
