// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Switch} from "../src/Switch.sol";

contract SwitchTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6721125);
    }

    function test_Increment() public {
        Switch switchCA = Switch(0x31cCd4B12dAc76Bba51C707c6d8598D6474B248e);

        // switchCA.flipSwitch(abi.encodeWithSignature("turnSwitchOn()"));

        (bool success,) = address(switchCA).call(abi.encodeWithSignature("turnSwitchOn()"));
        require(success, "Failed to turn switch on");

        console.log("switchOn: ", switchCA.switchOn());
    }
}
