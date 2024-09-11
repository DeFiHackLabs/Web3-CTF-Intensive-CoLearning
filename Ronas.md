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

- A. Ethernaut CTF - Level 4 Telephone
    - `tx.origin` 及 `msg.sender` 的差異
        - `tx.origin`: 發起交易的地址，通常為使用者的錢包地址
        - `msg.sender`: function 的呼叫者，可以為使用者錢包，或是另一個合約
    - 作法：寫一個合約代替直接發送，便可造成 `tx.origin` 及 `msg.sender` 出現不一致
    - [PoC](./Writeup/Ronas/Ethernaut%20CTF/PoC/level4_telephone.sol)

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

- A. Ethernaut CTF - Level 7 Force
    - 目標 `Force` 合約沒有 `fallback` 函數，因此無法透過 `fallback` 方式向目標發送 Ether
    - `selfdestruct` 是一個自毀函數，可將合約身上的所有 Ether 直接轉往另一個合約
    - [PoC](/Writeup/Ronas/Ethernaut%20CTF/PoC/level7_force.sol)
- takeaways
    - selfdestruct 函數

### 2024.09.05

- A. Ethernaut CTF - Level 8 Vault
    - 由於區塊鏈的公開透明特性，可以直接從合約的 storage 取得這些私有變數值 `web3.eth.getStorageAt(contract.address, 1)`
    - 解碼取得 password 值 `web3.utils.hexToAscii("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")`
    - Exploit `contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")`

- takeaways
    - nothing is private in the blockchain
    - any private data should either be stored off-chain, or carefully encrypted

### 2024.09.06

- [A. Ethernaut CTF - Level 9 King](/Writeup/Ronas/Ethernaut%20CTF/level9.md)

### 2024.09.07

- [A. Ethernaut CTF - level 10](/Writeup/Ronas/Ethernaut%20CTF/level10.md)

### 2024.09.09

- [A. Ethernaut CTF - level 11 Elevator](/Writeup/Ronas/Ethernaut%20CTF/level11.md)

### 2024.09.10

- [A. Ethernaut CTF - level 12 Privacy](/Writeup/Ronas/Ethernaut%20CTF/level12.md)

<!-- Content_END -->
