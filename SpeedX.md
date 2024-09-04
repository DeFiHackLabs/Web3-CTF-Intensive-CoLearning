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

再做下一个 Level 02 Fal1out:

这个感觉超级简单啊， 这个就是合约构造函数名字写错了， 我们直接调用合约Fal1out就可以了

```solidity
await contract.Fal1out({value: "0"})
```
但是提交的时候并没有通过，我想可能是因为我 send 0 ETH， 我又调用了合约的 allocate, 发送了 0.0001 ETH 

```solidity
await contract.allocate({value: toWei("0.0001")})
```

这样这一关就通过了, POC: 点这里(Writeup/SpeedX/src/Ethernaut/fal1out.sol)

**Level 03 Coin flip:**

本章使用 foundry 进行 POC 的编写和测试：

test sol 文件中使用 console.log 执行 forge test 的时候没有任何的输出，需要加参数 -vv

```
forge test -vv
```

**foundry 中使用 openzeppelin 库：**

```
forge install OpenZeppelin/openzeppelin-contracts@v4.9.6
```

根目录添加 remappings.txt, 添加映射

@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/

这样在 import 的时候就能找到 lib 的位置

这一关需要抛硬币连赢，连续 10 次都是正面 或者 背面，根据合约的逻辑，如果 hash / factor 的结果等于1 是 正面， 不等于 1 是 背面，直接调用不能保证每次都是一样的，我们要保证每次调用 flip 都能计算正确。

POC 合约的思路：

首先 调用 coin flip 之前计算好是否能连胜，如果可以再调用 flip 否则 返回 不调用 

POC代码: 点这里(Writeup/SpeedX/src/Ethernaut/coinflip_poc.sol)

使用 foundry 编写 coinflip_poc.sol 合约，并编写[测试合约](Writeup/SpeedX/test/Ethernaut/coinflip.sol) 

测试没有问题后， 把 coinflip.sol 和 coinflip_poc.sol 都部署到本地节点上测试， 然后再部署到 arb_sepolia上完成题目的 hack 。

```
forge create --rpc-url anvil --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Ethernaut/coinflip.sol:CoinFlip

[⠊] Compiling...
No files changed, compilation skipped
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Transaction hash: 0xfe6b3a48e8eb73907f801eb763967789b963e0080b54dc13aaa63fce6105989c


forge create --constructor-args "0x5FbDB2315678afecb367f032d93F642f64180aa3" --rpc-url anvil --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Ethernaut/coinflip_poc.sol:CoinFlipPOC

[⠊] Compiling...
No files changed, compilation skipped
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Transaction hash: 0xe1ed74878fc03fe0052678781fa3bda4ce07218e40d629402db14dc77384d2dc

```
编写 foundry script 自动执行 POC，代码 [Writeup/SpeedX/script/Ethernaut/coinflip_poc.sol](Writeup/SpeedX/script/Ethernaut/coinflip_poc.s.sol)

运行下面命令 执行POC 脚本, 没执行一次调用 10 次 flip 函数，需要多执行几次

使用 --slow 参数等待交易 confirm 再 send 下一个 tx， 并且添加 --skip-simulation

```
forge script --chain anvil --rpc-url anvil script/Ethernaut/coinflip_poc.s.sol:CoinFlipPOCScript -vvvv --slow  --skip-simulation --broadcast
```

### 2024.08.31

今天完成 Ethernaut Level 04 Telephone

tx.origin 为交易from 地址

msg.sender 为调用 Telephone 合约的 POC 合约地址

这个任务很简单写个简单的 POC 调用就可以了， [参考POC 代码](Writeup/SpeedX/src/Ethernaut/telephone_poc.sol)


昨天 Level 03 理解错了， 以为是连续的正面或者背面， 今天看了别人的原来是连续猜对， 今天修改一下代码。

**Level 05 Token**

这题考的是整数溢出，当出现负数就会溢出，就会出现很大的正数， 所以直接转账大于 20 就可以了。

这个 Token 合约使用的 0.6.0 版本的 solidity， 不会检查溢出，现在最新版本的会报错。 但是不要使用 unchecked 



[POC 代码](Writeup/SpeedX/src/Ethernaut/token_poc.sol)


**Level 06 Delegation**

直接调用 Delegation 合约 交易 data 为 delegate 合约函数 pwn()的签名

```
address(delegation).call(abi.encodeWithSignature("pwn()"));
```

A合约中 调用 B.delegatecall() B 合约中 msg.sender 与 A 合约的 msg.sender 相同 


[POC 代码](Writeup/SpeedX/script/Ethernaut/delegation_poc.s.sol)


### 2024.09.01

**Level 07 Force**

说实话，我尝试了好几个办法直接转账， 合约调用 transfer call 都不行， 实现不知道怎么弄了， 应该是还有其他我不知道的，于是我就求助 google 了，看看别人怎么做的。

原来是用的 selfdestruct,  POC 合约销毁的时候传入 Force合约地址就会把POC 合约的余额转给 Force 合约

[POC 代码](Writeup/SpeedX/script/Ethernaut/force_poc.s.sol)

**Level 08 Vault**

这个题，我尝试看是否有办法通过构造函数传入的数据来获取到 password ，但是没有找到。
我还是 google 去找答案了。

区块链上的变量都存在 slot 中可以，通过 slot 获取到，及时他是 private 的

```
web3.eth.getStorageAt(instance.address, 1, (err,res) => {
   contract.unlock(web3.utils.hexToAscii(res))
   //A very strong secret password :)
});
```

### 2024.09.02

**Level 09 King**

[POC 代码](Writeup/SpeedX/src/Ethernaut/king_poc.sol)

### 2024.09.03

**Level 09 King**

使用 POC 合约给 king 合约转账，因为 POC 合约没有 fallback 函数 不能接收 ETH 导致 king 不能被别人再次取代。

[POC 代码](Writeup/SpeedX/script/Ethernaut/king_poc.s.sol)

**Level 10 Re-entrancy**

重入漏洞，这个之前了解过，需要在转账之前，重新计算余额，否则递归调用会把余额全部花光， 因为余额并没有减少。

[POC 代码](Writeup/SpeedX/script/Ethernaut/reentrancy_poc.s.sol)


### 2024.09.04

<!-- Content_END -->
