// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Switch} from "../src/Switch.sol";

contract SwitchTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6708262);
    }

    function test_Increment() public {
        Switch switchCA = Switch(0x31cCd4B12dAc76Bba51C707c6d8598D6474B248e);
    }
}
