// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Base} from "src/Base.sol";
import "forge-std/console.sol";

contract BaseMock is Base {
    constructor(uint256 startTime, uint256 endTime, uint256 fullScore) Base(startTime, endTime, fullScore) {
        console.log("start mock constructor");
    }

    function setup() external override {
    }
}

contract BaseTest is Test {
    BaseMock public base;

    uint256 constant public TIME = 100;
    uint256 public startTime;
    uint256 public endTime;

    function setUp() external {
        startTime = block.timestamp + TIME;
        endTime = startTime + TIME;
    }

    function testGetCurrentScore(uint256 fullScore) public {
        fullScore = bound(fullScore, 0, TIME);
        base = new BaseMock(startTime, endTime, fullScore);
        uint256 score = base.getCurrentScore();
        assertEq(score, fullScore);
        skip(TIME); // to start time
        score = base.getCurrentScore();
        assertEq(score, fullScore);
        skip(TIME/2); // challenge ongoing
        uint256 oldScore = score;
        score = base.getCurrentScore();
        assertGe(oldScore, score);
        assertGe(score, 0);
        skip(TIME/2); // to end time
        oldScore = score;
        score = base.getCurrentScore();
        assertGe(oldScore, score);
        assertGe(score, 0);
        skip(1); // after end time
        score = base.getCurrentScore();
        assertEq(score, 0);
    }

    function testGetFinalScore(uint256 fullScore, uint256 solveTime) public {
        fullScore = bound(fullScore, 0, TIME);
        solveTime = bound(solveTime, 0, TIME * 2 - 1);
        base = new BaseMock(startTime, endTime, fullScore);
        skip(solveTime);
        base.solve();
        uint256 score = base.getCurrentScore();
        uint256 finalScore = base.getFinalScore();
        assertEq(score, finalScore);
        skip(1);
        uint256 oldFinalScore = finalScore;
        score = base.getCurrentScore();
        finalScore = base.getFinalScore();
        assertEq(finalScore, oldFinalScore);
        assertLe(score, finalScore);
        skip(TIME * 2); // to start time
        oldFinalScore = finalScore;
        finalScore = base.getFinalScore();
        assertEq(finalScore, oldFinalScore);
    }

    function testSolve(uint256 fullScore, uint256 solveTime) public {
        fullScore = bound(fullScore, 0, TIME);
        solveTime = bound(solveTime, 0, TIME * 2 - 1);
        base = new BaseMock(startTime, endTime, fullScore);
        skip(solveTime);
        assertFalse(base.isSolved());
        base.solve();
        assertTrue(base.isSolved());
    }
}
