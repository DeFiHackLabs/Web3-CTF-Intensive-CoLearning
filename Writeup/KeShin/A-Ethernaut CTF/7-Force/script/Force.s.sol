// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ForceTest} from "../test/Force.t.sol";

contract ForceScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6622705);
    }

    function run() public {
        vm.startBroadcast();

        ForceTest forceTest = new ForceTest();

        payable(address(forceTest)).transfer(0.01 ether);

        console.log("test contract balance : ", address(forceTest).balance);

        forceTest.test_Transfer();
        
        console.log("test contract balance : ", address(forceTest).balance);

        console.log("force contract balance : ", address(0x338905CCbAB72014BfCC822a5628615b0e01a611).balance);
    }
}
