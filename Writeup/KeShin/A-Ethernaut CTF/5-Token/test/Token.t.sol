// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6611751); 
    }

    function test_Transfer() public {
        // vm.startPrank(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);

        Token token = Token(0xe2792f6cf9D0320602A831631f0e9Bf22624b9a7);

        console.log("Before Balance : ", token.balanceOf(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d));

        token.transfer(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d, 20);

        console.log("After Balance : ", token.balanceOf(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d));
    }
}