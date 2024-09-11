// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PreservationTest} from "../test/Preservation.t.sol";

contract PreservationScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6671483);
    }

    function run() public {
        vm.startBroadcast();

        PreservationTest preservationTest = new PreservationTest();

        preservationTest.test_DelegateCall();
    }
}
