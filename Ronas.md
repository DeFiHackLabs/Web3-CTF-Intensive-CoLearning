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

- A. Ethernaut CTF - Level 1 Fallback
    - 要取得這份 Solidity 智能合約的所有權，需要滿足以下條件
        - 利用 `contribute()` 函數：當使用 `contribute()` 函數進行捐款時，如果貢獻超過當前擁有者的貢獻，將成為新的擁有者
        - 利用 `receive()` 函數：如果您已經在 `contributions` 中有貢獻（大於0），可以通過直接向合約地址發送超過 0 的 ETH 來觸發 `receive()` 函數，這樣合約的擁有者將被設置為 `msg.sender` 的地址
    - 步驟
        - `contract.contribute({value:1})` 確保已經有貢獻: 首先，需要使用 `contribute()` 函數進行少量捐款（小於 `0.001 ether`），以便在 `contributions` 中創建地址條目，這樣將有機會在後續步驟中獲得所有權
        - `contract.sendTransaction({value:1})` 向合約發送 ETH，以觸發 receive() 函數
        - `msg.sender` 將成為新的擁有者
        - `contract.withdraw()` 提取所有的錢

- takeaways
    - 了解 Fallback 函數

### 2024.08.30

- A. Ethernaut CTF - Level 2 Fallout
    - 這個合約並沒有 constructor (應該要是一個名為 `Fallout` 的函數，但只見一個 `Fal1out` 函數)，這可能發生在改變合約名稱時沒有改變 constructor 名稱，或純粹打錯字
    - 這使任何人都可以去調用 `Fal1out` 函數，取得合約所有權
    - PoC `contract.Fal1out()`

- takeaways
    - 了解合約建構函數及一般函數

### 2024.08.31

- A. Ethernaut CTF - Level 3 Coin Flip
    - 此題如同大部分偽隨機數的問題，產生隨機數的種子可預測，隨機數便可預測，此題運用區塊雜湊除以一個固定的 FACTOR，兩者皆為已知情況下，所產生的隨機數便不安全，產生的硬幣正反面結果便可預測，破壞此遊戲理想勝應有的 50% 勝率
    - 由於手算每次正反面結果有點辛苦，編寫攻擊合約來達成是較可行的做法
    - [PoC](./Writeup/Ronas/Ethernaut%20CTF/PoC/level3_coinflip.sol)

- takeaways
    - 偽隨機數問題
    - 撰寫攻擊合約

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

<!-- Content_END -->
