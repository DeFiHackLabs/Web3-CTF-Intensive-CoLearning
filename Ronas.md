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
    - [PoC](./Writeup/Ronas/Ethernaut%20CTF/level3_coinflip.sol)

- takeaways
    - 偽隨機數問題
    - 撰寫攻擊合約

<!-- Content_END -->
