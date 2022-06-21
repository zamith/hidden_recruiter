pragma solidity ^0.8.0;

import {Game, IVerifier} from "src/Game.sol";
import {AgentAskVerifier} from "build/AgentAsk/AgentAskVerifier.sol";

contract GameTest {
    AgentAskVerifier verifier;
    Game game;

    function setUp() public {
        verifier = new AgentAskVerifier();
        game = new Game(address(verifier));
    }

    function testGameCreation() public {
        address[] memory agents = new address[](1);
        agents[0] = 0x71C7656EC7ab88b098defB751B7401B5f6d8976F;

        uint256 movesHash = 12161705107552638055056582591684085142116555511696014104619902267786701619978;
        game.startGame(123, agents, movesHash);

        assert(game.agents(123, 0) == agents[0]);
        assert(game.movesHashes(123) == movesHash);

        (uint8 x, uint8 y) = game.features(Game.Features.RED, 1);
        assert(x == uint8(1));
        assert(y == uint8(5));
    }
}
