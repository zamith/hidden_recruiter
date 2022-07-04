// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../build/AgentAsk/AgentAskVerifier.sol";
import "../../build/AgentAskNoMatch/AgentAskNoMatchVerifier.sol";
import "../../build/AgentCapture/AgentCaptureVerifier.sol";
import "../../build/AgentReveal/AgentRevealVerifier.sol";
import "../../build/StartingMove/StartingMoveVerifier.sol";
import "../../build/RecruiterMove/RecruiterMoveVerifier.sol";

contract Game {
    AgentAskVerifier public agentAskVerifier;
    AgentAskNoMatchVerifier public agentAskNoMatchVerifier;
    AgentCaptureVerifier public agentCaptureVerifier;
    AgentRevealVerifier public agentRevealVerifier;
    StartingMoveVerifier public firstMoveVerifier;
    RecruiterMoveVerifier public recruiterMoveVerifier;

    event AgentMoved(address indexed agent, Position to);
    event AgentAsked(address indexed agent, Feature feature);
    event AgentRevealed(address indexed agent, Position pos);
    event AgentCaptured(address indexed agent, Position pos);
    event RecruiterMoved();
    event AskAnswered();
    event CaptureAnswered();
    event RevealAnswered();

    enum Feature {
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
        STARTED,
        RECRUITER_WON,
        AGENTS_WON
    }

    struct Position {
        uint8 x;
        uint8 y;
    }

    struct Token {
        uint256 number;
        bool numberRevelead;
        bool revealed;
    }

    struct Round {
        uint256 number;
        bool recruiterMoved;
        uint256 numberOfAgentsActed;
        mapping(address => bool) agentsMoved;
        mapping(address => bool) agentsActed;
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
    // game id to agent to exists
    mapping(uint256 => mapping(address => bool)) agentInGame;
    // features to positions with those features
    mapping(Feature => Position[]) public features;

    // x, y, feature
    mapping(uint256 => mapping(uint256 => Feature[])) positionToFeatures;

    // game id, x, y, token
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Token)))
        public tokens;

    uint256 public nextGameId;

    mapping(uint256 => Feature) public currentAgentAsk;
    mapping(uint256 => bool) public hasAsk;

    mapping(uint256 => Position) public currentAgentReveal;
    mapping(uint256 => bool) public hasReveal;

    mapping(uint256 => Position) public currentAgentCapture;
    mapping(uint256 => bool) public hasCapture;

    constructor(
        address _agentAskVerifier,
        address _firstMoveVerifier,
        address _recruiterMoveVerifier,
        address _agentAskNoMatchVerifier,
        address _agentCaptureVerifier,
        address _agentRevealVerifier
    ) {
        agentAskVerifier = AgentAskVerifier(_agentAskVerifier);
        firstMoveVerifier = StartingMoveVerifier(_firstMoveVerifier);
        recruiterMoveVerifier = RecruiterMoveVerifier(_recruiterMoveVerifier);
        agentAskNoMatchVerifier = AgentAskNoMatchVerifier(
            _agentAskNoMatchVerifier
        );
        agentCaptureVerifier = AgentCaptureVerifier(_agentCaptureVerifier);
        agentRevealVerifier = AgentRevealVerifier(_agentRevealVerifier);
        addFeature(Feature.RED, [0, 1, 3, 5, 5], [0, 5, 4, 1, 3]);
        addFeature(Feature.BLUE, [1, 4, 4, 0, 5], [0, 1, 3, 5, 6]);
        addFeature(Feature.GREEN, [2, 3, 1, 3, 0], [0, 2, 3, 5, 6]);
        addFeature(Feature.YELLOW, [3, 1, 3, 1, 2], [0, 1, 3, 4, 6]);
        addFeature(Feature.PURPLE, [4, 2, 5, 0, 4], [0, 2, 2, 3, 5]);
        addFeature(Feature.ORANGE, [5, 2, 3, 5, 1], [0, 5, 1, 4, 6]);
        addFeature(Feature.BLACK, [0, 1, 2, 4, 2], [1, 2, 3, 6, 4]);
        addFeature(Feature.WHITE, [0, 2, 0, 4, 3], [2, 1, 4, 4, 6]);
    }

    modifier gameStatus(uint256 gameId, GameStatus status) {
        require(
            gameStatuses[gameId] == status,
            "Invalid game status for action"
        );
        _;
    }

    modifier onlyRecruiter(uint256 gameId) {
        require(recruiters[gameId] == msg.sender, "Not the recruiter");
        _;
    }

    modifier onlyAgent(uint256 gameId) {
        require(agentInGame[gameId][msg.sender], "Not an agent");
        _;
    }

    function agentsNeeded(uint256 gameId) public view returns (bool) {
        return
            agents[gameId].length < 4 &&
            gameStatuses[gameId] == GameStatus.OPEN;
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
        uint256 numAgents = agents[gameId].length;
        require(numAgents >= 0 && numAgents <= 4, "Invalid number of agents");
        agents[gameId].push(agent);
        agentInGame[gameId][agent] = true;
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
            address agent = agents[gameId][i];
            agentPositions[gameId][agent] = startingPositions[i];
            emit AgentMoved(agent, startingPositions[i]);
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
        uint256[2] memory input
    )
        public
        onlyRecruiter(gameId)
        gameStatus(gameId, GameStatus.RECRUITER_INITIAL_MOVES)
    {
        uint256 numberOfMoves = movesHashes[gameId].length;
        require(numberOfMoves == 0, "Recruiter already made a move");
        require(
            firstMoveVerifier.verifyProof(a, b, c, input),
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
        uint256[4] memory input
    )
        public
        onlyRecruiter(gameId)
        gameStatus(gameId, GameStatus.RECRUITER_INITIAL_MOVES)
    {
        uint256 numberOfMoves = movesHashes[gameId].length;
        require(numberOfMoves < 5, "Too many initial moves");
        require(
            recruiterMoveVerifier.verifyProof(a, b, c, input),
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
        uint256[4] memory input
    ) public onlyRecruiter(gameId) gameStatus(gameId, GameStatus.STARTED) {
        Round storage round = rounds[gameId];
        require(!round.recruiterMoved, "Recruiter already moved");
        require(
            recruiterMoveVerifier.verifyProof(a, b, c, input),
            "Failed to verify proof"
        );

        movesHashes[gameId].push(moveHash);
        round.recruiterMoved = true;
        emit RecruiterMoved();
    }

    function agentMove(
        uint256 gameId,
        uint8 x,
        uint8 y
    ) public gameStatus(gameId, GameStatus.STARTED) onlyAgent(gameId) {
        Round storage round = rounds[gameId];
        require(round.recruiterMoved, "Recruiter has not moved yet");
        require(!round.agentsMoved[msg.sender], "Agent already moved");

        Position memory currentPosition = agentPositions[gameId][msg.sender];
        uint8 xDelta = x > currentPosition.x
            ? x - currentPosition.x
            : currentPosition.x - x;
        uint8 yDelta = y > currentPosition.y
            ? y - currentPosition.y
            : currentPosition.y - y;

        if (xDelta == 2 && yDelta != 0) {
            revert("Invalid move");
        }

        if (yDelta == 2 && xDelta != 0) {
            revert("Invalid move");
        }

        if (xDelta > 1 || yDelta > 1) {
            revert("Invalid move");
        }

        Position memory newPosition = Position(x, y);
        agentPositions[gameId][msg.sender] = newPosition;
        round.agentsMoved[msg.sender] = true;
        emit AgentMoved(msg.sender, newPosition);
    }

    function agentAskNotify(uint256 gameId, uint256[2] calldata position)
        public
    {
        Round storage round = rounds[gameId];
        require(round.recruiterMoved, "Recruiter has not moved yet");
        require(!round.agentsActed[msg.sender], "Agent already acted");

        Feature feature = positionToFeatures[position[0]][position[1]][0];
        currentAgentAsk[gameId] = feature;
        hasAsk[gameId] = true;
        round.agentsActed[msg.sender] = true;
        round.numberOfAgentsActed++;
        emit AgentAsked(msg.sender, feature);

        if (round.numberOfAgentsActed == numberOfAgents(gameId)) {
            newRound(gameId);
        }
    }

    function agentRevealNotify(uint256 gameId, uint256[2] calldata position)
        public
    {
        Round storage round = rounds[gameId];
        require(round.recruiterMoved, "Recruiter has not moved yet");
        require(!round.agentsActed[msg.sender], "Agent already acted");
        Position memory currentPosition = Position(
            uint8(position[0]),
            uint8(position[1])
        );

        currentAgentReveal[gameId] = currentPosition;
        hasReveal[gameId] = true;
        round.agentsActed[msg.sender] = true;
        round.numberOfAgentsActed++;
        emit AgentRevealed(msg.sender, currentPosition);

        if (round.numberOfAgentsActed == numberOfAgents(gameId)) {
            newRound(gameId);
        }
    }

    function agentCaptureNotify(uint256 gameId, uint256[2] calldata position)
        public
    {
        Round storage round = rounds[gameId];
        require(round.recruiterMoved, "Recruiter has not moved yet");
        require(!round.agentsActed[msg.sender], "Agent already acted");
        Position memory currentPosition = Position(
            uint8(position[0]),
            uint8(position[1])
        );

        currentAgentCapture[gameId] = currentPosition;
        hasCapture[gameId] = true;
        round.agentsActed[msg.sender] = true;
        round.numberOfAgentsActed++;
        emit AgentCaptured(msg.sender, currentPosition);

        if (round.numberOfAgentsActed == numberOfAgents(gameId)) {
            newRound(gameId);
        }
    }

    function agentAskRevealPosition(
        uint256 gameId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[27] memory input
    ) public onlyRecruiter(gameId) gameStatus(gameId, GameStatus.STARTED) {
        require(
            agentAskVerifier.verifyProof(a, b, c, input),
            "Failed to verify proof"
        );

        tokens[gameId][input[11]][input[12]] = Token(0, false, true);
        hasAsk[gameId] = false;
        emit AskAnswered();
    }

    function agentAskRevealNoPosition(
        uint256 gameId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[25] memory input
    ) public onlyRecruiter(gameId) gameStatus(gameId, GameStatus.STARTED) {
        require(
            agentAskNoMatchVerifier.verifyProof(a, b, c, input),
            "Failed to verify proof"
        );

        hasAsk[gameId] = false;
        emit AskAnswered();
    }

    function agentCapture(
        uint256 gameId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) public onlyRecruiter(gameId) gameStatus(gameId, GameStatus.STARTED) {
        require(
            agentCaptureVerifier.verifyProof(a, b, c, input),
            "Failed to verify proof"
        );

        hasCapture[gameId] = false;
        if (input[0] == 1) {
            gameStatuses[gameId] = GameStatus.AGENTS_WON;
        }
        emit CaptureAnswered();
    }

    function agentReveal(
        uint256 gameId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) public onlyRecruiter(gameId) gameStatus(gameId, GameStatus.STARTED) {
        require(
            agentRevealVerifier.verifyProof(a, b, c, input),
            "Failed to verify proof"
        );
        Token storage token = tokens[gameId][input[0]][input[1]];
        token.number = input[2];
        token.numberRevelead = true;

        hasReveal[gameId] = false;
        emit RevealAnswered();
    }

    function addFeature(
        Feature feature,
        uint8[5] memory x,
        uint8[5] memory y
    ) internal {
        for (uint8 i = 0; i < 5; i++) {
            Position memory position = Position(x[i], y[i]);
            features[feature].push(position);
            positionToFeatures[position.x][position.y].push(feature);
        }
    }

    function newRound(uint256 gameId) internal {
        Round storage round = rounds[gameId];
        address[] memory gameAgents = agents[gameId];
        uint256 numberOfRounds = round.number + 1;

        if (numberOfRounds > 14) {
            gameStatuses[gameId] = GameStatus.RECRUITER_WON;
            return;
        }

        for (uint256 i = 0; i < round.numberOfAgentsActed; i++) {
            delete round.agentsActed[gameAgents[i]];
            delete round.agentsMoved[gameAgents[i]];
        }

        round.number = numberOfRounds;
        round.recruiterMoved = false;
        round.numberOfAgentsActed = 0;
    }

    function min(uint256 a, uint256 b) external pure returns (uint256) {
        return a >= b ? b : a;
    }
}
