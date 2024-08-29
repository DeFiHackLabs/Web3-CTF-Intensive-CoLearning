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

<!-- Content_END -->
