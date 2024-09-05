// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {KingTest} from "../test/King.t.sol";

contract KingScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6631128);
    }

    function run() public {
        vm.startBroadcast();

        // KingTest kingTest = new KingTest();
        KingTest kingTest = KingTest(payable(0xb9ED500481C4cD39D02f415273bcB3C3Bf7565Ad));

        // payable(address(kingTest)).call{value: 0.001 ether}("");

        kingTest.test_BeatKing();
    }
}
