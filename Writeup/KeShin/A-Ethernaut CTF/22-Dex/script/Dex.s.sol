// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Dex} from "../src/Dex.sol";

contract DexScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6684541);
    }

    function run() public {
        vm.startBroadcast();

        address dexAddress = 0x90aAF6E7A323a01081228d57a023831f6E397DAC;
        Dex dex = Dex(dexAddress);

        address user = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;

        address token1 = dex.token1();
        address token2 = dex.token2();

        dex.approve(dexAddress, 5000);

        for(uint256 i = 1; i <= 5; i++) {
            if(i%2 == 0) {
                dex.swap(token2, token1, dex.balanceOf(token2, user));
            } else {
                dex.swap(token1, token2, dex.balanceOf(token1, user));
            }

            console.log("Swap times : ", i);

            console.log("user balance : ", dex.balanceOf(token1, user), dex.balanceOf(token2, user));

            console.log("contract balance : ", dex.balanceOf(token1, dexAddress), dex.balanceOf(token2, dexAddress));

            console.log("\n");
        }

        console.log("price : ", dex.getSwapPrice(token2, token1, 65)); // 158 
    }
}
