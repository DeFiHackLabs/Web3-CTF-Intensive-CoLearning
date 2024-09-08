---
timezone: Asia/Shanghai 
---

# KeShin

1. 自我介绍

KeShin, 合约安全新人

2. 你认为你会完成本次残酷学习吗？

尽力而为

## Notes

<!-- Content_START -->

### 2024.08.29

笔记内容

#### [Ethernaut CTF : 0 Hello Ethernaut](https://ethernaut.openzeppelin.com/level/0)
- 介绍了Ethernaut CTF 的玩法，如何使用浏览器的console进行交互，通过引导完成了此关

#### [Ethernaut CTF : 1 Fallback](https://ethernaut.openzeppelin.com/level/1)

- 可以通过 contribute 函数多次发送小于 0.001 ether的金额到合约，当用户的余额大于 1000 时，合约的 owner 就会变成我们，然后我们可以调用 withdraw 取走此合约所有的 ether 使其余额为 0。
- 但是我们又没有 1000 个 ETH，我们注意到合约有 receive 函数，可以直接修改 owner，但其判断条件必须用户的贡献大于 0 。
- 所以我们先调用 contribute 随意贡献一点，然后转 ETH 到合约，receive 被触发使 owner 修改，然后调用 withdraw 取走合约所有 ETH 即可。
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/1-Fallback)

### 2024.08.30

#### [Ethernaut CTF : 2 Fallout](https://ethernaut.openzeppelin.com/level/2)
- 直接调用 Fal1out 函数就可以拿到 owner 权限
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/2-Fallout)

#### [Ethernaut CTF : 3 CoinFlip](https://ethernaut.openzeppelin.com/level/3)
- 随机数问题，依赖的 blockHash 和 blockNumber 都是可预测的，答案可以提前算出来
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/3-CoinFlip)
- 本地模拟能过，但是提交到链上后，blockHash和blockNumber变了，导致答案变了，如何及时将正确结果及时提交到链上，还需要再研究研究

### 2024.08.31
- 昨天的 CoinFlip 题目的链下模拟与链上执行答案不一致的问题，是因为forge script 广播后，其区块高度已经发生了改变，所以不能直接在 script 中计算答案，应该部署一个攻击合约，在合约的逻辑中计算答案，然后提交给 CoinFlip 合约

#### [Ethernaut CTF : 4 Telephone](https://ethernaut.openzeppelin.com/level/4)
- 让 tx.origin 和 msg.sender 不一致即可
- 我们创建一个中介合约来进行调用
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/4-Telephone)

### 2024.9.1
#### [Ethernaut CTF : 5 Token](https://ethernaut.openzeppelin.com/level/5)
- 整数下溢问题，由于EVM版本问题，当 balance[msg.sender] < _value 时，减去之后会得到一个很大的数，会通过检查
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/5-Token)

### 2024.9.2
#### [Ethernaut CTF : 6 Delegation](https://ethernaut.openzeppelin.com/level/6)
- 理解 delegatecall 和 call 的区别
- 理解 abi encode 相关
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/6-Delegation/)

### 2024.9.3
#### [Ethernaut CTF : 7 Force](https://ethernaut.openzeppelin.com/level/7)
- 一个合约需要有 receive 或者 fallback来接收 ETH, 当这两个都不存在时，可以通过调用带有 payable 的函数来接收 ETH。
- 当这些都不存在时，可以创建另一个合约，通过 selfdestruct 自毁可以将当前合约的 ETH 强制发送给某一地址，坎昆升级后，自毁只是发送走所有的 ETH ，代码不会被删除
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/7-Force/)

### 2024.9.4
#### [Ethernaut CTF : 8 Vault](https://ethernaut.openzeppelin.com/level/8)
- 虽然 password 被标记为 private 不能直接读取，但是我们可以通过 foundry 直接从合约的存储槽 slot 位置直接读取出值
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/8-Vault/)

#### [Ethernaut CTF : 9 King](https://ethernaut.openzeppelin.com/level/9)
- 转一点钱就可以拿到合约的 king 
- 但是提交 instance 的时候，他们会再次尝试获取拿到 king ，我们看到其合约用的是 transfer ,有 gas 限制，我们只需要在攻击合约的 receive 中实现复杂的逻辑，使其尝试失败既可以
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/9-King/)


### 2024.9.5
#### [Ethernaut CTF : 10 Reentrance](https://ethernaut.openzeppelin.com/level/10)
- 在我们攻击合约中重入 withdraw 函数
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/10-Reentrance/)

### 2024.9.6
#### [Ethernaut CTF : 11 Elevator](https://ethernaut.openzeppelin.com/level/11)
- 在攻击合约中实现 isLastFloor 接口即可
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/11-Elevator/)

### 2024.9.7
#### [Ethernaut CTF : 12 Privacy](https://ethernaut.openzeppelin.com/level/12)
- 使用 forge inspect Privacy storage 可以查看合约的存储槽布局
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/12-Privacy/)

### 2024.9.8

### 2024.9.9

<!-- Content_END -->
