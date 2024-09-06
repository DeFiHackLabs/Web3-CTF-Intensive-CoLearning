---
timezone: Asia/Shanghai
---

# Slark

1. 自我介绍
    - freelancer / quanter / mev searcher
2. 你认为你会完成本次残酷学习吗？
    - 尽力而为，快乐学习。踏上取经路，比抵达灵山更重要 🐒

## Notes

<!-- Content_START -->

### 2024.08.29

今天打卡 A 系列 `ethernaut`，尝试 2 个关卡

- [level0](https://ethernaut.openzeppelin.com/level/0x7E0f53981657345B31C59aC44e9c21631Ce710c7) 
    - [POC](./Writeup/Slark/test/ethernaut//level0.t.sol) 
    - 这个关卡的主要目的是熟悉合约的读写交互，主要过程是引导访问合约的 `info()` 读方法，会给出下一个方法名的提示，一直到 `password()` 读方法，最后提交 `authenticate()` 写方法，使得 `getCleared()` 返回 true 即可过关。
- [level1](https://ethernaut.openzeppelin.com/level/0x3c34A342b2aF5e885FcaA3800dB5B205fEfa3ffB)
    - [POC](./Writeup/Slark/test/ethernaut//level1.t.sol) 
    - 这个关卡合约存在业务逻辑的设计缺陷，只要调用过 `contribute()` 方法，就可以满足 `receive()` 中的条件，从而改变 owner，即可达到过关条件。 

### 2024.08.30

今天打卡 A 系列 `ethernaut`，水过 1 个关卡

- [level2](https://ethernaut.openzeppelin.com/level/0x676e57FdBbd8e5fE1A7A3f4Bb1296dAC880aa639)
    - [POC](./Writeup/Slark/test/ethernaut//level2.t.sol)
    - 这个关卡比较水，单纯是 constructor 函数拼写错误，导致预期只在初始化执行的函数，变成了无限制可调用的写函数。直接调用，即可完成 owner 权限变更。
    
### 2024.08.31

今天打卡 A 系列 `ethernaut`，1 个关卡

- [level3](https://ethernaut.openzeppelin.com/level/0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF)
    - [POC](./Writeup/Slark/test/ethernaut//level3.t.sol)
    - 这个关卡设计的猜谜游戏，生成规则基于已经生成的区块数，属于可以“预测”的情况，只需要和生成规则保持一致，即可计算结果，从而达到一定猜中的结果。

### 2024.09.01


今天打卡 A 系列 `ethernaut`，1 个关卡

- [level4](https://ethernaut.openzeppelin.com/level/0x478f3476358Eb166Cb7adE4666d04fbdDB56C407)
    - [POC](./Writeup/Slark/test/ethernaut//level4.t.sol)
    - 这个关卡重点在于 uint 的计算溢出，实际上 0.8.0 solidity 应该不会有这个问题了。

### 2024.09.03

今天打卡 A 系列 `ethernaut`，1 个关卡

- [level6](https://ethernaut.openzeppelin.com/level/0x73379d8B82Fda494ee59555f333DF7D44483fD58)
    - [POC](./Writeup/Slark/test/ethernaut//level6.t.sol)
    - 这个关卡重点在于考察对 delegatecall 的掌握，实际上是传递了调用者 msg.sender 但修改的是 Delegation 中的数据，因此出现了问题。

### 2024.09.04

今天打卡 A 系列 `ethernaut`，1 个关卡
- [level8](https://ethernaut.openzeppelin.com/level/0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670)
    - [POC](./Writeup/Slark/test/ethernaut//level8.t.sol)
    - 这个关卡重点在于考察 EVM 的存储模型的认知，实际上 private 成员变量依然是可见的

### 2024.09.05

今天打卡 A 系列 `ethernaut`，1 个关卡
- [level9](https://ethernaut.openzeppelin.com/level/0x3049C00639E6dfC269ED1451764a046f7aE500c6)
    - [POC](./Writeup/Slark/test/ethernaut//level9.t.sol)
    - 这个关卡打破游戏规则的核心，就是参与以后，阻止下一次转账的执行，那么可以创建一个攻击合约，在 constructor 中参与游戏，在 fallback 中制止游戏，即可达到目标

<!-- Content_END -->
