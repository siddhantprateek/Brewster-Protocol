// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {

    // amount of LINK to send with the request
    uint256 public fee;

    // ID of public key against the randomness is generated
    bytes32 public keyHash;

    // Address of the Player
    address[] public players;

    // Max number of players in one game
    uint8 maxPlayers;

    // Variable to indicate if the game has started or not
    bool public gameStarted;

    // the fees for entering the game
    uint256 entryFee;

    // current game id
    uint256 public gameId;

    // emitted when the game starts
    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);

    // emitted when someone joins the game
    event PlayerJoined(uint256 gameId, address players);

    // emitted when teh game ends
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    // constructor inherit VRFConsumerBase
    constructor(address vrfCoordinator, address linkToken,
    bytes32 vrfKeyHash, uint256 vrfFee) 
    VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFee;
        gameStarted = false;
    }

    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        // check if there is a game already running
        require(!gameStarted, "Game is currently Running");
        // empty player array
        delete players;
        // set the max players to this game
        maxPlayers = _maxPlayers;
        // set the game started to true
        gameStarted = true;
        // setup the entry Fee for the game
        entryFee = _entryFee;
        gameId += 1;
        emit GameStarted(gameId, maxPlayers, entryFee);

    }


    function joinGame() public payable {
        // check if the game is already running
        require(gameStarted, "Game has not been started yet");
        // check if the value sent by the user matches the entryFee 
        require(msg.value == entryFee, "Value sent is not equal to entryFee");
        // check if there is still some space left in the game to add another player
        require(players.length < maxPlayers, "Game is full");
        // add the sender to the players list
        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);

        // if the list is full start the winner selection process
        if(players.length == maxPlayers) {
            // getRandomWinner();
        }

    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {

        // we want out winnerIndex to be in the length from 0 to players.length - 1
        // for this we mod the it with the players.length value

        uint256 winnerIndex = randomness % players.length;
        // get the address of the winner from the players array
        address winner = players[winnerIndex];
        // send the ether in the contract to the winner
        (bool sent,) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        // Emit that game has ended
        emit GameEnded(gameId, winner, requestId);
        // set the gameStarted variable to false
        gameStarted = false;
    }
}