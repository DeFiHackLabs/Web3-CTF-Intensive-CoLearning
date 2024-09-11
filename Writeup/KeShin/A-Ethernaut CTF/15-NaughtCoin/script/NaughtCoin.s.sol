// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NaughtCoin} from "../src/NaughtCoin.sol";

contract NaughtCoinScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6666159);
    }

    function run() public {
        vm.startBroadcast();

        NaughtCoin naughtCoin = NaughtCoin(0x7278a538B5a28fD7474901b0dcda84a9Ae25F640);

        console.log(naughtCoin.timeLock());

        vm.store(address(naughtCoin), bytes32(uint256(5)), bytes32(block.timestamp));
        
        console.log(naughtCoin.timeLock());
        
        naughtCoin.transfer(address(0), 1000000 * (10 ** 18));
    }
}
