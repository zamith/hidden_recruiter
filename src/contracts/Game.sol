// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../build/AgentAsk/AgentAskVerifier.sol";
import "../../build/StartingMove/StartingMoveVerifier.sol";
import "../../build/RecruiterMove/RecruiterMoveVerifier.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view returns (bool);
}

contract Game {
    IVerifier public agentAskVerifier;
    IVerifier public firstMoveVerifier;
    IVerifier public recruiterMoveVerifier;

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

    enum GameStatus {
        NOT_OPEN,
        OPEN,
        RECRUITER_INITIAL_MOVES,
        STARTED
    }

    struct Position {
        uint8 x;
        uint8 y;
    }

    struct Round {
        uint256 number;
        bool recruiterMoved;
        address[] agentsMoved;
    }

    // game id to moves hash
    mapping(uint256 => uint256[]) public movesHashes;
    // game id to agents
    mapping(uint256 => address[]) public agents;
    // game id to game status
    mapping(uint256 => GameStatus) public gameStatuses;
    // game id to recruiter
    mapping(uint256 => address) public recruiters;
    // game id to round
    mapping(uint256 => Round) public rounds;
    // game id to agent positions
    mapping(uint256 => mapping(address => Position)) public agentPositions;

    // features to positions with those features
    mapping(Features => Position[]) public features;

    uint256 public nextGameId;

    constructor(
        address _agentAskVerifier,
        address _firstMoveVerifier,
        address _recruiterMoveVerifier
    ) {
        agentAskVerifier = IVerifier(_agentAskVerifier);
        firstMoveVerifier = IVerifier(_firstMoveVerifier);
        recruiterMoveVerifier = IVerifier(_recruiterMoveVerifier);
        addFeature(Features.RED, [0, 1, 3, 4, 5], [0, 5, 4, 1, 3]);
        addFeature(Features.BLUE, [1, 4, 4, 0, 5], [0, 1, 3, 5, 6]);
        addFeature(Features.GREEN, [2, 3, 1, 3, 0], [0, 2, 3, 5, 6]);
        addFeature(Features.YELLOW, [3, 1, 3, 1, 2], [0, 1, 3, 4, 6]);
        addFeature(Features.PURPLE, [4, 2, 5, 0, 4], [0, 2, 2, 3, 5]);
        addFeature(Features.ORANGE, [5, 0, 3, 4, 1], [0, 1, 1, 5, 6]);
    }

    modifier gameStatus(uint256 gameId, GameStatus status) {
        require(gameStatuses[gameId] == status);
        _;
    }

    modifier onlyRecruiter(uint256 gameId) {
        require(recruiters[gameId] == msg.sender);
        _;
    }

    function agentsNeeded(uint256 gameId) public view returns (bool) {
        return agents[gameId].length < 4;
    }

    function numberOfRecruiterMoves(uint256 gameId)
        public
        view
        returns (uint256)
    {
        return movesHashes[gameId].length;
    }

    function numberOfAgents(uint256 gameId) public view returns (uint256) {
        return agents[gameId].length;
    }

    function addAgent(uint256 gameId, address agent)
        public
        gameStatus(gameId, GameStatus.OPEN)
    {
        uint256 numAgents = agents[gameId].length + 1;
        require(numAgents > 0 && numAgents <= 4, "Invalid number of agents");
        agents[gameId].push(agent);
    }

    function setRecruiter(uint256 gameId, address recruiter)
        public
        gameStatus(gameId, GameStatus.OPEN)
    {
        require(recruiters[gameId] == address(0));
        recruiters[gameId] = recruiter;
    }

    function openGame(uint256 gameId)
        public
        gameStatus(gameId, GameStatus.NOT_OPEN)
    {
        nextGameId = gameId + 1;
        gameStatuses[gameId] = GameStatus.OPEN;
    }

    function startGame(uint256 gameId)
        public
        onlyRecruiter(gameId)
        gameStatus(gameId, GameStatus.OPEN)
    {
        uint256 numAgents = numberOfAgents(gameId);
        gameStatuses[gameId] = GameStatus.RECRUITER_INITIAL_MOVES;
        Position[4] memory startingPositions = [
            Position(0, 0),
            Position(0, 7),
            Position(5, 0),
            Position(5, 7)
        ];
        for (uint256 i = 0; i < numAgents; i++) {
            agentPositions[gameId][agents[gameId][i]] = startingPositions[i];
        }
    }

    function endGame(uint256 gameId)
        public
        gameStatus(gameId, GameStatus.STARTED)
    {
        recruiters[gameId] = address(0);
        gameStatuses[gameId] = GameStatus.OPEN;
        delete movesHashes[gameId];
        delete agents[gameId];
    }

    function recruiterFirstMove(
        uint256 gameId,
        uint256 moveHash,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    )
        public
        onlyRecruiter(gameId)
        gameStatus(gameId, GameStatus.RECRUITER_INITIAL_MOVES)
    {
        uint256 numberOfMoves = movesHashes[gameId].length;
        require(numberOfMoves == 0, "Recruiter already made a move");
        require(
            verifyProof(recruiterMoveVerifier, a, b, c, input),
            "Failed to verify proof"
        );

        movesHashes[gameId].push(moveHash);
    }

    function recruiterMoveInitial(
        uint256 gameId,
        uint256 moveHash,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    )
        public
        onlyRecruiter(gameId)
        gameStatus(gameId, GameStatus.RECRUITER_INITIAL_MOVES)
    {
        uint256 numberOfMoves = movesHashes[gameId].length;
        require(numberOfMoves < 5, "Too many initial moves");
        require(
            verifyProof(recruiterMoveVerifier, a, b, c, input),
            "Failed to verify proof"
        );

        movesHashes[gameId].push(moveHash);
        if (numberOfMoves == 4) {
            gameStatuses[gameId] = GameStatus.STARTED;
            newRound(gameId);
        }
    }

    function recruiterMove(
        uint256 gameId,
        uint256 moveHash,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) public onlyRecruiter(gameId) gameStatus(gameId, GameStatus.STARTED) {
        Round memory round = rounds[gameId];
        require(!round.recruiterMoved, "Recruiter already moved");
        require(
            verifyProof(recruiterMoveVerifier, a, b, c, input),
            "Failed to verify proof"
        );

        movesHashes[gameId].push(moveHash);
        round.recruiterMoved = true;
    }

    function agentMove(
        uint256 gameId,
        uint8 x,
        uint8 y
    ) public gameStatus(gameId, GameStatus.STARTED) {
        Round storage round = rounds[gameId];
        require(round.recruiterMoved, "Recruiter has not moved yet");
        require(
            agentPositions[gameId][msg.sender].x != 0,
            "Agent does not have a position in this game"
        );

        agentPositions[gameId][msg.sender] = Position(x, y);
        round.agentsMoved.push(msg.sender);

        // Add after agent actions
        // if (round.agentsMoved.length == numberOfAgents(gameId)) {
        //     newRound(gameId);
        // }
    }

    function verifyProof(
        IVerifier verifier,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) public view returns (bool) {
        return IVerifier(verifier).verifyProof(a, b, c, input);
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

    function newRound(uint256 gameId) internal {
        uint256 numberOfRounds = rounds[gameId].number + 1;
        rounds[gameId] = Round(
            numberOfRounds,
            false,
            new address[](numberOfAgents(gameId))
        );
    }
}
