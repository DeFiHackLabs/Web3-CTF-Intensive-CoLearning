---
timezone: Asia/Shanghai
---

# phipupt

1. 自我介绍
   接触 web3 挺长时间了，一直浅尝则止，希望借这个机会深入学习下。
2. 你认为你会完成本次残酷学习吗？
   没问题

## Notes

<!-- Content_START -->

### 2024.08.29
The Ethernaut level 0
第一天打卡，内容比较简单，在控制台输入代码即可交互
![截屏2024-08-29 22 51 18](https://github.com/user-attachments/assets/bbf8c784-6562-46e2-9d66-4962a968b368)


### 2024.08.30
The Ethernaut level 1- 获取合约拥有权，并提取余额
只需要先调用 contribute 方法存入一笔资金，再转账任意数量 ether 带合约就可以获得 ownership，进而提取全部余额。
重新温习了 Foundry，写了个合约去调用。但是一直报错，还得再改改。


### 2024.08.31
调试了好久，终于成功了。

在 sepolia 重新部署了一个 level01 的 `Fallback` [合约](https://sepolia.etherscan.io/address/0xF6a32a802127712efAAED091Fa946492460Cb703#code)。

写了一个攻击合约去实现所有功能，攻击合约在[这里](Writeup/phipupt/ethernaut/script/Level01.s.sol)。  
具体实现逻辑：
1. 先给攻击合约一定数量的 ether，用于调用 `Fallback` 合约时发送 ether
2. 调用 `attack` 方法，该方法调用 `Fallback` 合约的 `contribute` 方法，存入一笔资金。再直接发送 1 wei 给 `Fallback` 合约，从而获取 `owner` 权限。
3. 最后再调用 `Fallback` 合约的 `withdraw` 方法（此时已经具有 `owner` 权限），成功提取所有资金

![示例代码](Writeup/phipupt/ethernaut/image.png)


<!-- Content_END -->
