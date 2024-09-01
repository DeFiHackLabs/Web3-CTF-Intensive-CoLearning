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
- [POC](./Writeup/KeShin/A-Ethernaut%20CTF/5-Token)

### 2024.9.2

### 2024.9.3

<!-- Content_END -->
