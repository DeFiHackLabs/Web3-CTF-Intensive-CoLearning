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


<!-- Content_END -->
