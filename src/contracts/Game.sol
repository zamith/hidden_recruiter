// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    // game id to moves hash
    mapping(uint256 => uint256) public movesHashes;
    // game id to agents
    mapping(uint256 => address[]) public agents;

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
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
}
