// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ReentranceTest} from "../test/Reentrance.t.sol";

contract ReentranceScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6642339);
    }

    function run() public {
        vm.startBroadcast();

        ReentranceTest reentranceTest = new ReentranceTest();

        payable(address(reentranceTest)).transfer(0.001 ether);

        reentranceTest.test_Withdraw();
    }
}
