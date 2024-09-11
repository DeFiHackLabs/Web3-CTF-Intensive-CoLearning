// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Recovery, SimpleToken} from "../src/Recovery.sol";

contract RecoveryTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6671552);
    }

    function test_Destroy() public {
        SimpleToken simpleToken = SimpleToken(payable(0xB691218Bb58946E42C175Bf3Aa55cAF60e706850));
        
        console.log("balance : ", address(simpleToken).balance);

        simpleToken.destroy(payable(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d));

        console.log("balance : ", address(simpleToken).balance);
    }
}
