---
timezone: Asia/Shanghai
---

# Alive

1. 自我介绍

   电子科技大学通信工程毕业，2020-2022深圳做过两年ios开发，2023开始接触链上撸毛，最近几个月想进一步学习区块链相关技能看能不能成为相关从业者。

2. 你认为你会完成本次残酷学习吗？

   应该会吧，每天挤出一两个小时应该没问题，只是不知道难度如何。

## Notes

<!-- Content_START -->

### 2024.08.29

解了下A系列习题的The Ethernaut的第0-8道题目。尽量都用foundry来解，时间有限，核心在快速把题目解出，代码的编排、规范可能差点。POC写在Writeup的foundry工程下。

这里讲讲各题的思路、感悟。

#### 第00题hello ethernaut

通过该例学习了下怎么用foundry与ethernaut互动

#### 第01题fallback

权限设置不当，通过适当的函数调用顺序即可获得合约所有权

#### 第02题fallout

调用fal1out即可

#### 第03题CoinFlip

链上数据都是透明，无法实现真正的随机，要随机数得通过chainlink

#### 第04题Telephone

主要是知道tx.orgin和msg.sender的区别

#### 第05题Token

solidity0.8.0之前是没有溢出检查的，需要用safemath来保证数据处理的安全。

#### 第06题Delegation

清楚call、delegatecall的用法即可解此题，想调函数时data可以abi.encodeWithSignature("functionName()")这种形式来传

#### 第07题Force

了解selfdestruct的用法即可解决。另外坎昆升级之后selfdestruct其实已被弃用，已经部署在链上的合约代码无法被真正删除。

#### 第08题Vault

同第03题，链上的所有东西都是透明的，千万不要把不想要别人知道的如钱包私钥的信息储存在链上。哪怕设置为private，也还是能通过slot读取到变量的值。

<!-- Content_END -->
