// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ShopHack} from "ethernaut/shop_hack.sol";
import "forge-std/console.sol";

contract ShopHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ShopHack shopHack = new ShopHack(0xE49af35511DC8638c86A4aF559df503E7B9cf76d);
        shopHack.hack();
        vm.stopBroadcast();
    }
}
