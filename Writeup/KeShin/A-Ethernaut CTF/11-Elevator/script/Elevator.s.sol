// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ElevatorTest} from "../test/Elevator.t.sol";

contract ElevatorScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6642458);
    }

    function run() public {
        vm.startBroadcast();

        ElevatorTest elevatorTest = new ElevatorTest();

        elevatorTest.test_GoTop();
    }
}
