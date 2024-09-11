// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NaughtCoin} from "../src/NaughtCoin.sol";

contract CounterTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6666159);
    }

    function test_Increment() public {
        vm.startPrank(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);
        
        NaughtCoin naughtCoin = NaughtCoin(0x7278a538B5a28fD7474901b0dcda84a9Ae25F640);

        console.log(naughtCoin.timeLock());

        vm.store(address(naughtCoin), bytes32(uint256(5)), bytes32(block.timestamp));

        console.log(naughtCoin.timeLock());

        naughtCoin.transfer(address(0x670B24610DF99b1685aEAC0dfD5307B92e0cF4d7), 1000000 * (10 ** 18));
    }
}
