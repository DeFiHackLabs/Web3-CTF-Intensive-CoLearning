// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {TokenTest} from "../test/Token.t.sol";

contract TokenScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com"); 
    }

    function run() public {
        vm.startBroadcast();

        // Token token = Token(0xe2792f6cf9D0320602A831631f0e9Bf22624b9a7);

        // console.log("Before Balance : ", token.balanceOf(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d));

        // token.transfer(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d, 20);

        // console.log("After Balance : ", token.balanceOf(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d));

        TokenTest tokenTest = new TokenTest();
        tokenTest.test_Transfer();
    }
}
