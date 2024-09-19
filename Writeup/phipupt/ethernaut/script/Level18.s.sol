// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MagicNum} from "../src/level18.sol";

contract Attacker {
    MagicNum level;

    constructor(address level_) {
        level = MagicNum(level_);
    }

    function attack() public {
        address solverInstance;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0x68, 0x69602A60005260206000F3600052600A6016F3))
            solverInstance := create(0, ptr, 0x13)
        }

        level.setSolver(solverInstance);
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0xdff2caaA0F67561139dB317905fE9636c5Ea2E99;

        Attacker attacker = new Attacker(levelAddr);

        attacker.attack();

        vm.stopBroadcast();
    }
}
