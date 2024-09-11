// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
// import "../src/levels/19-AlienCodex/AlienCodex.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

interface AlienCodex


contract Level19Solution is Script {
    AlienCodex _alienCodexInstance = AlienCodex(0x9771216E425e48D72993b0CC2bd40BAA7b72c319);

    function run() public{
        vm.startBroadcast();

        // make contact
        _alienCodexInstance.contact();
        console.log("slot 0", vm.load(address(_alienCodexInstance), bytes32(uint256(0))));
        vm.stopBroadcast();
    }
}