// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DexTwo} from "../src/DexTwo.sol";
import {MyToken} from "../test/DexTwo.t.sol";

contract DexTwoScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6690990);
    }

    function run() public {
        address dexTwoAddress = 0xa1Cae52D675ed1d738F87189BdEe3112B130F145;
        DexTwo dexTwo = DexTwo(dexTwoAddress);

        address token1 = dexTwo.token1();
        address token2 = dexTwo.token2();

        address user = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;

        vm.startBroadcast();

        MyToken myToken = new MyToken();

        myToken.approve(user, dexTwoAddress, 5000);

        myToken.transfer(dexTwoAddress, 100);

        // user : 1000 10
        // ca: 100 100
        // 100 = x * 100 / 100 -> x = 100
        dexTwo.swap(address(myToken), token1, 100);
        
        console.log("swap times : ", uint256(1));

        console.log("contract balance : ", myToken.balanceOf(dexTwoAddress), dexTwo.balanceOf(token1, dexTwoAddress), dexTwo.balanceOf(token2, dexTwoAddress));

        // user : 1000 10
        // ca: 200 100
        // 100 = x * 100 / 200 -> x = 200
        dexTwo.swap(address(myToken), token2, 200);
        
        console.log("swap times : ", uint256(2));

        console.log("contract balance : ", myToken.balanceOf(dexTwoAddress), dexTwo.balanceOf(token1, dexTwoAddress), dexTwo.balanceOf(token2, dexTwoAddress));
    }
}