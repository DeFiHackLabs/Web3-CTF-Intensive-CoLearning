// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/Ethernaut/coinflip.sol";

contract CoinFlipTest is Test {
    CoinFlip coinFlip;

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    uint256 lastHash;

    function setUp() public {
        coinFlip = new CoinFlip();
    }

    function test_ConsecutiveWinFlips() public {

        //print loop 10 times block number
        for (uint256 i = 0; i < 10; i++) {
            console.log("Block number:", block.number);
        }

    //   while (coinFlip.consecutiveWins() > 10) {
    //     assertEq(coinFlip.flip(true), true, "Flip i should be true");
    //   }
    }

    function check_flip_result(bool guess) internal {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
    }
    
}