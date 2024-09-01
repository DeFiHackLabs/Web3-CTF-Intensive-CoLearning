// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/Ethernaut/delegation.sol";

contract DelegationAttackScript is Script {
    Delegation public delegation =
        Delegation(0x425701B9808F71B057CA7777ddd3A130e2592D89);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vm.stopBroadcast();
    }
}
