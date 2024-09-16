// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GoodSamaritanTest} from "../test/GoodSamaritan.t.sol";

contract GoodSamaritanScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6701235);
    }

    function run() public {
        vm.startBroadcast();

        GoodSamaritanTest goodSamaritanTest = new GoodSamaritanTest();

        goodSamaritanTest.test_RequestDonation();
    }
}
