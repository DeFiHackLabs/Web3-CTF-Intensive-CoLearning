# 0 - Hello Ethernaut writeup

## 题目
[Fallback](https://ethernaut.openzeppelin.com/level/0x3c99F231E92c4F0009aC726dd310Bd76d1c755bB)

## 笔记 
```
我们在招聘！
logo
●○○○○

Fallback


Fallback level  image
现在你知道了一些 ether 如何进出合约的基础知识, 包括使用 fallback 方法.

你也学到了 OpenZeppelin 的 Ownable 合约, 以及他可以如何用来限制一些针对特权地址方法的使用.

当你准备好了, 就可以出发去下一关!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```

首先通过 `contract.contribute({value:1000})` 调用 contribute 函数发送一点以太坊给合约，使我的地址的 contributions[msg.sender] 数据有记录，
然后通过钱包给合约地址发送一笔以太坊以调用 `receive()` 函数，此时 owner 应该已经变为了我控制的地址，再调用 `withdraw()` 既可以把合约中的以太坊清空。
