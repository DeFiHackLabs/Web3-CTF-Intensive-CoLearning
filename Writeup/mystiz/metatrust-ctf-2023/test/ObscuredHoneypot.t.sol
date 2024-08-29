// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ObscuredHoneypot} from "../src/honeypot/ObscuredHoneypot.sol";

contract FooTest is Test {
    ObscuredHoneypot public honeypot;

    function testExploit() public {
        honeypot = new ObscuredHoneypot();

        // Exploit should be implemented here...

        assertTrue(honeypot.isSolved());
    }
}
