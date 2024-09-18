---
timezone: Asia/Taipei
---

# Ronas

1. 自我介绍
資安研究員 WEB3新手
2. 你认为你会完成本次残酷学习吗？
會

## Notes

<!-- Content_START -->

### 2024.08.29

- [A. Ethernaut CTF - Level 1 Fallout](/Writeup/Ronas/Ethernaut%20CTF/level1.md)

### 2024.08.30

- [A. Ethernaut CTF - Level 2 Fallout](/Writeup/Ronas/Ethernaut%20CTF/level2.md)

### 2024.08.31

- [A. Ethernaut CTF - Level 3 Coin Flip](/Writeup/Ronas/Ethernaut%20CTF/level3.md)

### 2024.09.02

- [A. Ethernaut CTF - Level 4 Telephone](/Writeup/Ronas/Ethernaut%20CTF/level4.md)

### 2024.09.03

- A. Ethernaut CTF - Level 5 Token
    - 這是一個從學習 C 語言開始就會面對到的問題：整數的 overflow 與 underflow
    - 觸發 underflow: 送超過20塊給作者或其他地址 `contract.transfer("0x31a3801499618d3c4b0225b9e06e228d4795b55d", 22)`

- A. Ethernaut CTF - Level 6 Delegation
    - `fallback()` 函數會在呼叫函數不存在時觸發
    - 藉由呼叫 `pwn()` (不存在於 `Delegation`)觸發 `Delegation` 合約的 `fallback` 函數，觸發 `fallback` 中的 `delegatecall` 呼叫 `Delegate` 的 `pwn()` 函數，便能取得合約所有權
    - 函數選擇器值應為 `keccak256("pwn()")` = `dd365b8b15d5d78ec041b851b68c8b985bee78bee0b87c4acf261024d8beabab` 取前四個byte `dd365b8b` (tool: https://cyberchef.org/#recipe=Keccak('256')&input=cHduKCk)
    - PoC `sendTransaction({from:"<my wallet>", to:"<instance>", data:"0xdd365b8b"})`

- takeaways
    - fallback 觸發時機 - 合約內沒有呼叫指定的函數
        > https://solidity-by-example.org/fallback/
    - delegatecall 用法

### 2024.09.04

- [A. Ethernaut CTF - level 7 Force](/Writeup/Ronas/Ethernaut%20CTF/level7.md)

### 2024.09.05

- [A. Ethernaut CTF - Level 8 Vault](/Writeup/Ronas/Ethernaut%20CTF/level8.md)

### 2024.09.06

- [A. Ethernaut CTF - Level 9 King](/Writeup/Ronas/Ethernaut%20CTF/level9.md)

### 2024.09.07

- [A. Ethernaut CTF - level 10](/Writeup/Ronas/Ethernaut%20CTF/level10.md)

### 2024.09.09

- [A. Ethernaut CTF - level 11 Elevator](/Writeup/Ronas/Ethernaut%20CTF/level11.md)

### 2024.09.10

- [A. Ethernaut CTF - level 12 Privacy](/Writeup/Ronas/Ethernaut%20CTF/level12.md)

### 2024.09.11

- [A. Ethernaut CTF - level 13 Gatekeeper One](/Writeup/Ronas/Ethernaut%20CTF/level13.md)

### 2024.09.12

- [A. Ethernaut CTF - level 14 Gatekeeper Two](/Writeup/Ronas/Ethernaut%20CTF/level14.md)

### 2024.09.13

- [A. Ethernaut CTF - level 15 NaughtCoin](/Writeup/Ronas/Ethernaut%20CTF/level15.md)

### 2024.09.14

- [A. Ethernaut CTF - level 16 Preservation](/Writeup/Ronas/Ethernaut%20CTF/level16.md)

### 2024.09.16

- [A. Ethernaut CTF - level 17 Recovery](/Writeup/Ronas/Ethernaut%20CTF/level17.md)

### 2024.09.17

- [A. Ethernaut CTF - level 18 MagicNum](/Writeup/Ronas/Ethernaut%20CTF/level18.md)
- [A. Ethernaut CTF - level 19 AlienCodex](/Writeup/Ronas/Ethernaut%20CTF/level19.md)
- [A. Ethernaut CTF - level 20 Denial](/Writeup/Ronas/Ethernaut%20CTF/level20.md)
- [A. Ethernaut CTF - level 21 Shop](/Writeup/Ronas/Ethernaut%20CTF/level21.md)

<!-- Content_END -->
