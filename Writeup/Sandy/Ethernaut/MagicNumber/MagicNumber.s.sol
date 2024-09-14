// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {MagicNum} from "../../src/Ethernaut/MagicNum.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        MagicNum magicNum = MagicNum(0x12C7619C91D11D1ad5e30a59458d8157e7962fb2);
        MagicNumberAttacker attack = new MagicNumberAttacker();
        attack.attack();
        vm.stopBroadcast();
    }
}
contract MagicNumberAttacker {
    address public challengeInstance = 0x12C7619C91D11D1ad5e30a59458d8157e7962fb2;
    
    function attack() external {
        bytes memory code = "\x60\x0a\x60\x0c\x60\x00\x39\x60\x0a\x60\x00\xf3\x60\x2a\x60\x80\x52\x60\x20\x60\x80\xf3";
        address solver;
        assembly {
            solver := create(0, add(code, 0x20), mload(code))
        }
        MagicNum(challengeInstance).setSolver(solver);
    }
}
