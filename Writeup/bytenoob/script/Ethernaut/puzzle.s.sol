// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract AttackPuzzleScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address level24 = 0x086d96259d019c3af4F5451602329f7613270Aa0;
        vm.stopBroadcast();
    }
}
