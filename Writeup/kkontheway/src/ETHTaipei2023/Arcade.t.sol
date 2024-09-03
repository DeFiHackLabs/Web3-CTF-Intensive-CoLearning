// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ArcadeBase, Arcade} from "../../src/ETHTaipei2023/Arcade/Arcade.sol";

contract ArcadeTest is Test {
    ArcadeBase public arcadeBase;
    Arcade public arcade;

    address public you;
    address public player1;
    address public player2;
    address public player3;
    address public player4;

    function setUp() external {
        you = makeAddr("You");
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;

        vm.startPrank(you);
        arcadeBase = new ArcadeBase(startTime, endTime, fullScore);
        arcadeBase.setup();
        vm.stopPrank();
        arcade = arcadeBase.arcade();

        player1 = arcadeBase.player1();
        player2 = arcadeBase.player2();
        player3 = arcadeBase.player3();
        player4 = arcadeBase.player4();

        vm.label(address(arcadeBase), "ArcadeBase");
        vm.label(address(arcade), "Arcade");
    }

    function testSetUp() public {
        assertEq(arcade.currentPlayer(), you);
        assertEq(arcade.getCurrentPlayerPoints(), 0);

        assertEq(arcade.scoreboard(player1), 80);
        assertEq(arcade.scoreboard(player2), 120);
        assertEq(arcade.scoreboard(player3), 180);
        assertEq(arcade.scoreboard(player4), 190);

        assertEq(arcade.numPlayers(), 5);
        assertEq(arcade.players(0), you);
        assertEq(arcade.players(1), player1);
        assertEq(arcade.players(2), player2);
        assertEq(arcade.players(3), player3);
        assertEq(arcade.players(4), player4);
    }

    function testEarn() public {
        vm.warp(10 minutes);
        vm.prank(you);
        arcade.earn();
        assertEq(arcade.scoreboard(you), 10);
        assertEq(arcade.lastEarnTimestamp(), block.timestamp);
    }

    function testRedeem() public {
        vm.warp(10 minutes);
        vm.startPrank(you);
        arcade.earn();
        arcade.redeem();
        vm.stopPrank();
        assertEq(arcade.scoreboard(you), 0);
        assertEq(arcade.balanceOf(you), 10);
    }

    function testChangePlayer() public {
        vm.prank(you);
        arcade.changePlayer(player1);
        assertEq(arcade.currentPlayer(), player1);
    }

    function testExploit_arcade() public {
        vm.warp(10 minutes);
        vm.startPrank(you);
        arcade.earn(); // Earn 10 points
        arcade.redeem(); // Mint 10 PRIZE
        arcade.changePlayer(player3); // Mint 190 PRIZE
        arcadeBase.solve();
        assertTrue(arcadeBase.isSolved());
        vm.stopPrank();
    }
}
