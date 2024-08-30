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

<!-- Content_END -->
