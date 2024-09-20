// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Stake} from "../src/Stake.sol";

contract StakeTest is Test {

    function setUp() public {
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }
}
