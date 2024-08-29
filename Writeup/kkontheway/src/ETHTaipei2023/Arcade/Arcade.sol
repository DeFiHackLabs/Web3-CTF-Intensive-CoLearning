// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A new Arcade is online.
// Let's see who can win over 200 PRIZE tokens.

import {Ownable} from "@openzeppelin-contracts-08/contracts/access/Ownable.sol";
import {ERC20, IERC20} from "@openzeppelin-contracts-08/contracts/token/ERC20/ERC20.sol";

import {Base} from "../Base.sol";

contract Arcade is ERC20("prize", "PRIZE"), Ownable {
    address public currentPlayer;
    address[] public players;
    uint256 public numPlayers;
    uint256 public lastEarnTimestamp;
    mapping(address player => uint256 points) public scoreboard;

    event PlayerEarned(address indexed player, uint256 currentPoints);
    event PlayerChanged(address indexed oldPlayer, address indexed newPlayer);

    modifier onlyPlayer() {
        require(msg.sender == currentPlayer, "Unauthorized");
        _;
    }

    constructor(address player) {
        currentPlayer = player;
    }

    function getCurrentPlayerPoints() public view returns (uint256) {
        return scoreboard[currentPlayer];
    }

    function isActivePlayer(address player) public view returns (bool) {
        for (uint256 i; i < numPlayers; ++i) {
            if (players[i] == player) {
                return true;
            }
        }
        return false;
    }

    function setPoints(address player, uint256 points) external onlyOwner {
        scoreboard[player] = points;
        if (!isActivePlayer(player)) {
            players.push(player);
            numPlayers++;
        }
    }

    /// @notice Earn 10 points at most once per 10 minutes
    function earn() external onlyPlayer {
        require(block.timestamp >= lastEarnTimestamp + 10 minutes, "Too frequent");
        address player = msg.sender;
        scoreboard[player] += 10;
        lastEarnTimestamp = block.timestamp;
        emit PlayerEarned(player, getCurrentPlayerPoints());
    }

    /// @notice Be cautious as you might lose the ability to earn and redeem points afterward
    function changePlayer(address newPlayer) external onlyPlayer {
        address oldPlayer = currentPlayer;
        emit PlayerChanged(_redeem(oldPlayer), _setNewPlayer(newPlayer));
    }

    /// @notice Redeem points for minting PRIZE tokens at 1:1 ratio
    function redeem() external onlyPlayer {
        _redeem(msg.sender);
    }

    function _redeem(address player) internal returns (address) {
        uint256 points = getCurrentPlayerPoints();
        _mint(player, points);
        delete scoreboard[player];

        return player;
    }

    function _setNewPlayer(address newPlayer) internal returns (address) {
        currentPlayer = newPlayer;
        return newPlayer;
    }
}

contract ArcadeBase is Base {
    address public constant player1 = 0x1111Ad317502Ba53c84BD2D859237D33846Ca2e7;
    address public constant player2 = 0x2222140D9A0809B35D88636E3dDeC37B6bDd7CB2;
    address public constant player3 = 0x33339741B46D6EE8adCc0d796dE2aB6Ea3E8dc2A;
    address public constant player4 = 0x4444bd21FA6Ec8846308e926B86D06b74f63f4aD;

    Arcade public arcade;
    address public you;

    constructor(uint256 startTime, uint256 endTime, uint256 fullScore) Base(startTime, endTime, fullScore) {}

    function setup() external override {
        arcade = new Arcade(msg.sender);
        you = msg.sender;

        // Set initial points for players
        arcade.setPoints(you, 0);
        arcade.setPoints(player1, 80);
        arcade.setPoints(player2, 120);
        arcade.setPoints(player3, 180);
        arcade.setPoints(player4, 190);
    }

    /// @notice Do you have 200 PRIZE?
    function solve() public override {
        require(IERC20(arcade).balanceOf(you) >= 190, "Unsolved");
        super.solve();
    }
}
