---
timezone: Asia/Shanghai
---

# {sivan}

1. 自我介绍,区块链安全岗位多年，主要做审计、研究等工作
2. 你认为你会完成本次残酷学习吗？每天抽出1-2小时时间学习，努力完成。

## Notes

<!-- Content_START -->

### 2024.08.29
- Ethernaut CTF中fallback以及fallout两个题目，题目比较简单，调用两次函数便可以解决.
- [2024.8.29](./Writeup/Sivan/2024.8.29)
### 2024.08.30
- Ethernaut CTF中CoinFlip以及Telephone两个题目，题目比较简单，需要了解evm调用机制.
- [2024.8.30](./Writeup/Sivan/2024.8.30)
### 2024.08.31
- Ethernaut CTF中Delegation以及Token两个题目，主要是利用delegatecall以及整数溢出的安全问题.
- [2024.8.31](./Writeup/Sivan/2024.8.31)
### 2024.09.02
- Ethernaut CTF中Force以及Vault两个题目，主要是需要了解到合约销毁机制，并且需要了解私有存储的读取方式.
- [2024.9.2](./Writeup/Sivan/2024.9.2)
### 2024.09.03
- Ethernaut CTF中King以及Reentrance两个题目，主要是需要了解到合约错误处理机制，合约可以拒绝接收eth；另一题是经典的重入问题.
- [2024.9.3](./Writeup/Sivan/2024.9.3)
### 2024.09.04
- Ethernaut CTF中Elevator以及Privacy两个题目，主要是需要合理控制合约调用的流程，并且需要了解合约存储方式.
- [2024.9.4](./Writeup/Sivan/2024.9.4)
### 2024.09.05
- Ethernaut CTF中GatekeeperOne以及GatekeeperTwo两个题目，主要是需要了解以太坊运行机制，包括调用机制、gas扣除机制、类型转换、合约部署机制等.
- [2024.9.5](./Writeup/Sivan/2024.9.5)
### 2024.09.06
- Ethernaut CTF中NaughtCoin以及Preservation两个题目，主要是需要了解以太坊ERC20代币的使用规则，以及delegatecall 的存储和访问规则。
- [2024.9.6](./Writeup/Sivan/2024.9.6)
### 2024.09.08
- Ethernaut CTF中Recovery以及Denial两个题目，主要是需要了解以太坊合约地址计算规则，以及如何在自己合约中使得交易失败。
- [2024.9.8](./Writeup/Sivan/2024.9.8)
### 2024.09.09
- Ethernaut CTF中Shop以及DEX两个题目，主要是需要了解到view函数无法修改storage，所以不能通过一个storage变量来进行函数流程控制，但我们可以通过读取其他合约的view函数来进行控制，这里两个price函数调用之间，isSold变量发生了改变，所以可以使用isSold变量来进行函数流程控制。DEX题目主要是要了解价格计算的数学逻辑，该题中不是采用的兑换后验证的机制，而是兑换前进行价格计算，那么再兑换过程中，价格一直变化，而来回兑换就能利用这里的价格变化窃取资金。
- [2024.9.9](./Writeup/Sivan/2024.9.9)
### 2024.09.10
- Ethernaut CTF中DEXTWO题目，主要是缺少地址检查，可以传入自己的合约来返回恶意的数据。
- [2024.9.10](./Writeup/Sivan/2024.9.10)
<!-- Content_END -->
