// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Dex} from "../src/Dex.sol";

contract DexTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6684451);
    }

    function test_Swap() public {
        address dexAddress = 0x90aAF6E7A323a01081228d57a023831f6E397DAC;
        Dex dex = Dex(dexAddress);

        address user = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;
        vm.startPrank(user);

        address token1 = dex.token1();
        address token2 = dex.token2();

        console.log("dex owner : ", dex.owner()); // level address

        console.log("user balance : ", dex.balanceOf(token1, user), dex.balanceOf(token2, user));

        console.log("contract balance : ", dex.balanceOf(token1, dexAddress), dex.balanceOf(token2, dexAddress));

        dex.approve(dexAddress, 5000);

        // dex.swap(token1, token2, 10);

        // console.log("user balance : ", dex.balanceOf(token1, user), dex.balanceOf(token2, user));

        // console.log("contract balance : ", dex.balanceOf(token1, dexAddress), dex.balanceOf(token2, dexAddress));

        // dex.swap(token2, token1, 20);

        // console.log("user balance : ", dex.balanceOf(token1, user), dex.balanceOf(token2, user));

        // console.log("contract balance : ", dex.balanceOf(token1, dexAddress), dex.balanceOf(token2, dexAddress));

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

        // user : 0 65
        // contract : 110 45
        // swapAmount = 65 * 110 / 45 -> 158
        // 110 = x * 110 / 45 -> x = 45

        dex.swap(token2, token1, 45);

        console.log("Swap times : ", uint256(6));

        console.log("user balance : ", dex.balanceOf(token1, user), dex.balanceOf(token2, user));

        console.log("contract balance : ", dex.balanceOf(token1, dexAddress), dex.balanceOf(token2, dexAddress));


    }

}
