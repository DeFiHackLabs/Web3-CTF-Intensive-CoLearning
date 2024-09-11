// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MagicNum} from "../src/MagicNum.sol";

contract MagicNumTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6671581);
    }

    function test_Increment() public {
        MagicNum magicNum = MagicNum(0xCf54eD6Fe33a7D59a120545c72d3f7613379c87A);
    }

}
