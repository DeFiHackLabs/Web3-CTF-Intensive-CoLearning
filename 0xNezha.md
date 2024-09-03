---
timezone: Asia/Shanghai
---

> 请在上边的 timezone 添加你的当地时区，这会有助于你的打卡状态的自动化更新，如果没有添加，默认为北京时间 UTC+8 时区
> 时区请参考以下列表，请移除 # 以后的内容

---

# 0xNezha

1. 自我介绍
[0x哪吒](https://x.com/0xNezha).
2. 你认为你会完成本次残酷学习吗？
hmm... 希望这次不要分心 XD

## Notes

<!-- Content_START -->

### 2024.08.29

配置相关环境，使用 Foundry Cast 与合约交互，完成 Ethernaut 之 [00_Hello Ethernaut](./Writeup/0xNezha/Ethernaut/00_Hello%20Ethernaut.md) 

### 2024.08.30
在以太坊智能合约中，receive 函数是一个特殊的函数，用于接收以太币。当合约地址接收到以太币时，这个函数会被自动调用。[01_Fallback](./Writeup/0xNezha/Ethernaut/01_Fallback.md) 

### 2024.08.31
在 0.4.22 版本之前, 构造函数被定义为合约的同名函数（该语法在0.5.0之后弃用）。合约作者准备把Fal1out() 作为 合约 Fallout 的构造函数，以在合约部署时调用。但很不巧，笔误写错了，导致任何人都可以调用。[02_Fallout](./Writeup/0xNezha/Ethernaut/02_Fallout.md)

### 2024.09.02
一个猜硬币函数，输入参数是 true/false , 判断逻辑是：区块hash 与 FACTOR 进行除法运算，结果等于 1 则 side 这个变量为 true，不等于 1 则变量为 false。
判断输入参数是否等于函数的运算结果。相等则加 1 分，不相等则分数清零。
通过编写一个有着相同运算逻辑的合约，对结果进行提前运算。然后调用目标合约的函数，把运算结果输入进去，实现每次都猜中。[03_CoinFlip](./Writeup/0xNezha/Ethernaut/03_CoinFlip/src/CoinFlip_exp.sol)

<!-- Content_END -->
