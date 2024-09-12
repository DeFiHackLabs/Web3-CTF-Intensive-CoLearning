// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ShopTest} from "../test/Shop.t.sol";

contract ShopScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6676195);
    }

    function run() public {
        vm.startBroadcast();

        ShopTest shopTest = new ShopTest();

        shopTest.test_Buy();
    }
}
