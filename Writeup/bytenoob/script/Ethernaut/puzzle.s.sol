// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract AttackPuzzleScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address level24 = 0xCa8F3EC44380Bb22eC127F32E8e8d0477CF47D98;
        vm.stopBroadcast();
    }
}
