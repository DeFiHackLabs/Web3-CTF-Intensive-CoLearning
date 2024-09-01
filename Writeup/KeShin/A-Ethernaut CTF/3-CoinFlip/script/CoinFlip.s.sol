// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CoinFlipTest} from "../test/CoinFlip.t.sol";

contract CoinFlipScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com"); 
    }

    function run() public {
        vm.startBroadcast();        

        // CoinFlipTest coinFlipTest = new CoinFlipTest();
        // console.log("Attack Contract : ", address(coinFlipTest));

        CoinFlipTest coinFlipTest = CoinFlipTest(0xDe8DF57f46F24Aa816522D73698d2792b01518DC);

        // 允许 script 10 次
        coinFlipTest.test_guess();
    }
}
