// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GatekeeperThreeTest} from "../test/GatekeeperThree.t.sol";

contract GatekeeperThreeScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6708338);
    }

    function run() public {
        vm.startBroadcast();

        payable(0x81d01dB5A1e09759c8b6AE892c0796b38DafA681).transfer(0.0011 ether);

        GatekeeperThreeTest gatekeeperThreeTest = new GatekeeperThreeTest();

        gatekeeperThreeTest.test_Enter();
    }
}
