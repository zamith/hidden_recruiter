pragma solidity ^0.8.0;

import {Game} from "src/Game.sol";
import {StartingMoveVerifier} from "build/StartingMove/StartingMoveVerifier.sol";
import {RecruiterMoveVerifier} from "build/RecruiterMove/RecruiterMoveVerifier.sol";
import {AgentAskVerifier} from "build/AgentAsk/AgentAskVerifier.sol";
import {AgentAskNoMatchVerifier} from "build/AgentAskNoMatch/AgentAskNoMatchVerifier.sol";
import {AgentCaptureVerifier} from "build/AgentCapture/AgentCaptureVerifier.sol";
import {AgentRevealVerifier} from "build/AgentReveal/AgentRevealVerifier.sol";

contract GameTest {
    StartingMoveVerifier startingMoveVerifier;
    RecruiterMoveVerifier recruiterMoveVerifier;
    AgentAskVerifier agentAskVerifier;
    AgentAskNoMatchVerifier agentAskNoMatchVerifier;
    AgentRevealVerifier agentRevealVerifier;
    AgentCaptureVerifier agentCaptureVerifier;
    Game game;

    function setUp() public {
        startingMoveVerifier = new StartingMoveVerifier();
        recruiterMoveVerifier = new RecruiterMoveVerifier();
        agentAskVerifier = new AgentAskVerifier();
        agentAskNoMatchVerifier = new AgentAskNoMatchVerifier();
        agentRevealVerifier = new AgentRevealVerifier();
        agentCaptureVerifier = new AgentCaptureVerifier();
        game = new Game(
            address(agentAskVerifier),
            address(startingMoveVerifier),
            address(recruiterMoveVerifier),
            address(agentAskNoMatchVerifier),
            address(agentCaptureVerifier),
            address(agentRevealVerifier)
        );
    }

    function testGameCreation() public {
        address[] memory agents = new address[](1);
        agents[0] = 0x71C7656EC7ab88b098defB751B7401B5f6d8976F;

        uint256 movesHash = 12161705107552638055056582591684085142116555511696014104619902267786701619978;
        game.openGame(123);
        game.setRecruiter(123, agents[0]);
        game.addAgent(123, agents[0]);
        game.startGame(123);

        assert(game.agents(123, 0) == agents[0]);

        (uint8 x, uint8 y) = game.features(Game.Feature.RED, 1);
        assert(x == uint8(1));
        assert(y == uint8(5));
    }
}
