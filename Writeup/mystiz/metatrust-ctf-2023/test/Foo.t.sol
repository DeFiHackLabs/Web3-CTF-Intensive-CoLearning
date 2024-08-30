// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Foo} from "../src/foo/Foo.sol";

contract FooTest is Test {
    Foo public foo;

    function testExploit() public {
        foo = new Foo();

        // Exploit should be implemented here...

        assertTrue(foo.isSolved());
    }
}
