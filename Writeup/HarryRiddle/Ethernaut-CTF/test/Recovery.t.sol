// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Recovery} from "../src/Recovery.sol";

contract RecoveryTest is Test {
    Recovery target;
    RecoveryHacker hackTarget;

    function setUp() public {
        target = new Recovery();
        hackTarget = new RecoveryHacker();
    }

    function test_RecoveryToReceiveEther() public {
        address lostcontract = hackTarget.hack(address(target));
        assert(lostcontract != address(0));
    }
}

contract RecoveryHacker {
    function hack(address target) public pure returns (address lostcontract) {
        lostcontract = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            address(target),
                            bytes1(0x01)
                        )
                    )
                )
            )
        );
    }
}
