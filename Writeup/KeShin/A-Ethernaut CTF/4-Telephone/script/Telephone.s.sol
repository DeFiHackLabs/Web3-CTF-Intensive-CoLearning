// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TelephoneTest} from "../test/Telephone.t.sol";

contract TelephoneScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com");
    }

    function run() public {
        vm.startBroadcast();
        TelephoneTest telephoneTest = new TelephoneTest();

        telephoneTest.test_ChangeOwner();
    }
}
