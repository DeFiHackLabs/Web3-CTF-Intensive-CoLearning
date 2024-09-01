// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract TelephoneTest is Test {
    Counter public counter;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com"); 
    }

    function test_Increment() public {
        // counter.increment();
        // assertEq(counter.number(), 1);
    }

}
