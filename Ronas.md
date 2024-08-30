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
        - 確保已經有貢獻 `contract.contribute({value:1})`: 首先，需要使用 `contribute()` 函數進行少量捐款（小於 `0.001 ether`），以便在 `contributions` 中創建地址條目，這樣將有機會在後續步驟中獲得所有權
        - 向合約發送 ETH，以觸發 receive() 函數 `contract.sendTransaction({value:1})`
        - `msg.sender` 將成為新的擁有者
        - `contract.withdraw()` 提取所有的錢

### 2024.08.30

- A. Ethernaut CTF - Level 2 Fallout
    - 這個合約並沒有 constructor (應該要是一個名為 `Fallout` 的函數，但只見一個 `Fal1out` 函數)，這可能發生在改變合約名稱時沒有改變 constructor 名稱，或純粹打錯字
    - 這使任何人都可以去調用 `Fal1out` 函數，取得合約所有權
    - PoC `contract.Fal1out()`

<!-- Content_END -->
