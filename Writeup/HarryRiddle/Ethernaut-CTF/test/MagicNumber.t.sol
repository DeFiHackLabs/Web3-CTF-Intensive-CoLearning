// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {MagicNum} from "../src/MagicNumber.sol";

contract MagicNumTest is Test {
    MagicNum target;

    function setUp() public {
        target = new MagicNum();
    }

    function test_SetSolver() public {
        MagicNumHacker hackTarget = new MagicNumHacker();
        bytes
            memory byteCode = hex"600a600c600039600a6000f3602a60505260206050f3";
        hackTarget.createSolver(address(target), byteCode);
    }
}

contract MagicNumHacker {
    function createSolver(address target, bytes memory code) public {
        address solver;
        assembly {
            solver := create(0, add(code, 0x20), 0x13)
        }

        MagicNum(target).setSolver(solver);
    }
}
