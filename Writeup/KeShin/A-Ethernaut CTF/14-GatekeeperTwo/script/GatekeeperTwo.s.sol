// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Attack} from "../test/GatekeeperTwo.t.sol";

contract GatekeeperTwoScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6665896);
    }

    function run() public {
        vm.startBroadcast();

        Attack attack = new Attack();
    }
}
