// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GatekeeperOneTest} from "../test/GatekeeperOne.t.sol";

contract GatekeeperOneScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6665596);
    }

    function run() public {
        vm.startBroadcast();

        GatekeeperOneTest gatekeeperOneTest = new GatekeeperOneTest();

        gatekeeperOneTest.test_Enter();
    }
}
