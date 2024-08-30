// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "Ethernaut/coinflip_poc.sol";

contract CoinFlipTest is Test {
    CoinFlip coinFlip;

    CoinFlipPOC coinFlipPoc;
    function setUp() public {
        coinFlip = new CoinFlip();
        coinFlipPoc = new CoinFlipPOC(address(coinFlip));
    }

    function test_ConsecutiveWinFlips() public {
        
        while (coinFlip.consecutiveWins() < 10) {
            vm.roll(block.number + 1);
            // coinFlipPoc.flip();
            try coinFlipPoc.flip() returns (bool result) {
                console.log("flip result is", result);
            } catch Error(string memory reason) {
                console.log("flip failed with reason:", reason);
                break;
            }
        }
        
        assertEq(coinFlip.consecutiveWins(), 10, "Consecutive wins should be 10");
    }
}