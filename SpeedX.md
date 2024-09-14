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

今天完成 Ethernaut **Level 04 Telephone**

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
今天继续 Re entrancy POC 已经写好了， test 也通过了，但是 script 上正式就是不行呢， 奇怪了

又重新部署了一下代码， 重新跑 POC script 过了

继续下一关

**Level 11 Elevator**
电梯的 POC 合约我显示了 Building接口


### 2024.09.05
**Level 12 Privacy**
今天继续下一关 

### 2024.09.06
零点了 6 号了， 在这里写了， 这一关还是使用 web3.eth.getStorageAt(address, index) 函数来解决， 但是这一次稍微复杂一点就是，不足 32 字节并且合并后不会超过32 字节的变量会使用同一个槽 slot

经过分析， bool locked 使用一个 32 字节 slot index 0 (因为后面 ID 是 32 字节）， uint256 ID 32 字节 使用 slot 1， uint8 flatting 1字节, uint8 denomination 1字节 , uint16 awkwardness 两个字节， 他们三个一共 4 个字节 后面的 data[0] 32字节， 所以他们三个 flatting， denomination， awkwardness 可以使用 一个 slot , slot 2

| Slot index | Fields|
|-------------|-------------|
|slot-0 | locked|
|slot-1 | ID|
|slot-2 | awkwardness|denomination|flattening|
|slot-3 | data[0]|
|slot-4 | data[1]|
|slot-5 | data[2]|

unlock 函数判断的是 传入的 key 是否等于 bytes16(data[2]) 

通过 data[2]就是 slot 5,   web3.eth.getStorageAt(address, 5) 0x8de7238b78942005fea750232d184d0ce84a53d569bd7c825b99b79d02c50d1c

bytes16(data[2]) 从左边截取 16 个字节 0x8de7238b78942005fea750232d184d0c， 我开始从右边截取的，不对，我又从左边截取 16 个字节

然后直接在 console 中 发起交易 

```
await contract.unlock("0x8de7238b78942005fea750232d184d0c")
```

[POC 代码](Writeup/SpeedX/src/Ethernaut/privacy_poc.sol)


下一题

**Level 13 GatekeeperOne**

### 2024.09.07

昨天卡在 gateTwo gasleft()， 看了文档说 调用函数的时候可以设置 gas， 但是现在不知道 gasleft 的时候具体花费了多少 gas ，所以不知道 调用 enter的时候设置多少 gas 合适

test 测试没有问题 但是script 上链 上不去 不知道为什么，先跳过下一题了


**Level 14 GatekeeperTwo**

gateone tx.origin 为交易发起的地址 msg.sender 要不一样 可以用一个合约来调用 instance 合约 

### 2024.09.08

继续 gatekeeperTwo

gatetwo modifier caller() 为 应该是跟 msg.sender 一样 extcodesize(caller()) 如果为 0，caller() 应该为 EOA 地址或者 在 caller 的构造函数中调用 enter 函数 

gateThree ^ 为异或符号 如果 不同为 1 相同为 0， type(uint64).max 为 64位无符号整形，即 所有 64 位全部为 1， 16 进制为0xFFFFFFFF。 

```solidity
uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey)   == type(uint64).max 
```

这个结果要满足，就要 uint64(_gateKey) 与  uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) 结果完全相反

我们知道 如果 a ^ b = c，那么 a ^ c = b 

所以 uint64(_gateKey) 就是 uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ type(uint64).max

[POC 代码](Writeup/SpeedX/src/Ethernaut/gatekeepertwo_poc.sol)

### 2024.09.09
这两天有点忙，刚搞出来点时间写笔记 

今天继续 **Level 15 Naught Coin**

看了半天没思路， google ，原来是用 approve 和 transferFrom 


[POC 代码](Writeup/SpeedX/script/Ethernaut/naughtcoin.s.sol)

### 2024.09.10
**Level 16 preservation**
今天下一关，说实话还是没看懂，感觉是代理的存储 slot 的利用，来修改 owner 的存储。
写个 test 测试一下。

delegatecall 代理的 storage 还是 Preservation 合约的存储，只是逻辑写在了 timezoneLibrary 里


### 2024.09.11

**Level 16 preservation**
这一段也不简单啊，简单写了个测试，但是不知道为什么 timeZone1Library 赋值给 preservation合约后地址 与 timeZone1Library 合约地址不一样了

今天 arb sepolia 又创建不了new instance合约 

### 2024.09.12
这几天rpc网络不好呢， 创建instance 合约都不行，我先看看下一关吧

**Level 17 recovery**
这个还行比较简单， 从区块浏览器中 internal transaction中找到 生成的合约的contract 地址， 然后通过remix IDE，调用 SimpleToken 的 destroy 函数，这样就把SimpleToken合约中的代币转移走了

RPC突然好用了， 我测试了一下 调用 setFirstTime， setSecondTime 会把 timeZone1Library 变量替换掉，如果把 timeZone1Library 替换成另一个合约， 这个合约的第三个变量为 owner，那么再调用 setFirstTime，传入新的 owner地址 就可以修改 owner了

[POC 代码](Writeup/SpeedX/script/Ethernaut/preservation_poc.s.sol)

### 2024.09.13

**Level 17 recovery**

昨天可能是合约搞错了， 今天重新创建了一个instance 合约，直接console里面调用， 我在remix里面不好使 不知道为什么。通过了这一关

继续下一关 

**Level 18 MagicNumber**
### 2024.09.13

今天继续有点晚了， 先打卡再肝。




<!-- Content_END -->
