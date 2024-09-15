// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DexTwo} from "../src/DexTwo.sol";

contract DexTwoTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6690658);
    }

    function test_Swap() public {
        address dexTwoAddress = 0xa1Cae52D675ed1d738F87189BdEe3112B130F145;
        DexTwo dexTwo = DexTwo(dexTwoAddress);

        address token1 = dexTwo.token1();
        address token2 = dexTwo.token2();

        address user = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;
        vm.startPrank(user);

        dexTwo.approve(dexTwoAddress, 5000);

        for(uint256 i = 1;i <= 5;i++) {
            console.log("swap times : ", i);
            if(i%2 == 1) {
                dexTwo.swap(token1, token2, dexTwo.balanceOf(token1, user));
            } else {
                dexTwo.swap(token2, token1, dexTwo.balanceOf(token2, user));
            }

            console.log("user balance : ", dexTwo.balanceOf(token1, user), dexTwo.balanceOf(token2, user));

            console.log("contract balance : ", dexTwo.balanceOf(token1, dexTwoAddress), dexTwo.balanceOf(token2, dexTwoAddress));
        }

        // user : 0 65
        // contract : 110 45
        // swapAmount = 65 * 110 / 45 -> 158
        // 110 = x * 110 / 45 -> x = 45

    }
}
