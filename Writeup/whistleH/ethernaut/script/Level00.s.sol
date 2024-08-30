// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/levels/00-Hello/Level00.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Level0Solution is Script {

    Instance public level0 = Instance(0x0c49511429317D3B4E308Eab5185090c1Fe752BC);

    function run() external {
        vm.startBroadcast();
        
        // get the password
        string memory password = level0.password();
        console.log("Password: ", password);

        // authenticate
        level0.authenticate(password);
        vm.stopBroadcast();
    }
}