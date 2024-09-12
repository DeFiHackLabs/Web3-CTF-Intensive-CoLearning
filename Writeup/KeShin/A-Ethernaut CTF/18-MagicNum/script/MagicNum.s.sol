// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MagicNumTest} from "../test/MagicNum.t.sol";

contract CMagicNumScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6675909);
    }

    function run() public {
        vm.startBroadcast();

        MagicNumTest magicNumTest = new MagicNumTest();

        magicNumTest.test_Solver();
    }
}
