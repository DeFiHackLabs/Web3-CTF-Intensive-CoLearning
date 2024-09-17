// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Motorbike} from "../src/Motorbike.sol";

contract MotorbikeTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6696996);
    }

    function test_Increment() public {
    }

}
