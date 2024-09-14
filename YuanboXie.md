---
timezone: Asia/Shanghai
---


# YuanboXie

1. 自我介绍: 非ctfer，目前在研究安全算法，希望补一些安全基础
2. 你认为你会完成本次残酷学习吗？事情比较多，尽力

## Notes

<!-- Content_START -->

### 2024.08.29

- 1.Ethernaut CTF (31) - Hello Ethernaut - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 入门题，通过这个学习了如何做这个 web3 CTF;
- 1.Ethernaut CTF (31) - Fallback - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学习了如何在 console 与合约交互，如果目标合约的 function 有 payable，不会触发 receive 函数，而直接和合约转账会触发 receive 函数；

### 2024.08.30

- 1.Ethernaut CTF (31) - Fallout - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 这关想教我们的如果关键函数有拼写错误会导致严重后果，要注意仔细检查代码中的 typos；

### 2024.08.31

- 1.Ethernaut CTF (31) - Colin Flip - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 了解了不安全的随机数实现导致的安全问题（可预测），并学会了编写攻击合约；

### 2024.09.01

- 周天放假；

### 2024.09.02

- 1.Ethernaut CTF (31) - Telephone - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学会了 tx.origin 和 msg.sender 的区别；

### 2024.09.03

- 1.Ethernaut CTF (31) - Token - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学会了整数溢出漏洞；

### 2024.09.04

- 1.Ethernaut CTF (31) - Delegation - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学会了 delegatecall 导致的权限提升攻击；

### 2024.09.05

- 1.Ethernaut CTF (31) - Force - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学习了 selfdestruct，同时领悟到通过合约来攻击合约可以实现很多 tx 本身无法实现的操作，因为合约有更强的能力；

### 2024.09.06

- 1.Ethernaut CTF (31) - Vault - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 说明的 private 变量并不是真正的 private，相反，链上所有的数据本质上都是公开的。要真正保护隐私变量的话，得需要用到零知识证明或者同态加密；

### 2024.09.07

- 1.Ethernaut CTF (31) - King - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 收获：在传统领域的很多逻辑是不会出错的，但是在链上，收款地址本身也可以是程序逻辑的一部分，这种思维在 web3 里一定要转变过来，反是和第三方地址交互的地方都可以通过布置特定合约来实现恶意目的；

### 2024.09.08

- 周天放假；

### 2024.09.09

- 1.Ethernaut CTF (31) - Re-entrancy - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学习了智能合约经典漏洞：重入漏洞；

### 2024.09.10

- 1.Ethernaut CTF (31) - Elevator - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)

### 2024.09.11

- 1.Ethernaut CTF (31) - Privacy - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)

### 2024.09.12

- 1.Ethernaut CTF (31) - Gatekeeper One - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
   - 结合昨天和今天学习内容，学到了 bytes 和 uint 变量内存布局的区别;

### 2024.09.13

- 1.Ethernaut CTF (31) - Gatekeeper Two - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 对 solidity assembly 有了初步了解；
- 1.Ethernaut CTF (31) - Naught Coin - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学习了 ERC20 标准，除了 transfer，还有 approve + transferFrom 的授权转账机制；

### 2024.09.14

- 1.Ethernaut CTF (31) - Preservation - [writeup](./Writeup/YuanboXie/EthernautCTF-writeup.md)
    - 学习了 call 误用成了 delegateCall 导致的安全问题，以及通过 sstore 绕过变量定义直接对修改存储操的值；


<!-- Content_END -->