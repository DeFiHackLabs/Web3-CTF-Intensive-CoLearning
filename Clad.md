---
timezone: Asia/Taipei
---

# {Clad}

1. Hello World
2. 你认为你会完成本次残酷学习吗？我用盡全力

## Notes

<!-- Content_START -->

### 2024.08.29
學習內容:  
目標: 嘗試創建題目和繳交  
筆記:  
  參考教學: [Ethernaut Foundry Solutions 2024 - How to Start + Challenge 0 Solution](https://www.youtube.com/watch?v=UWy-CcnulCA&t=1406s)  
  foundry 架構  
  ->src 放置題目 code  
  ->script 放置你的答案 code  
  ->script script/Lev1Sol.s.sol 測試程式  
  ->script script/Lev1Sol.s.sol --broadcast  
  
### 2024.08.30
學習內容:  
今天總算把環境搞定，並成功運行解題的程式碼。接下來會盡量整理解題的過程，和整理筆記的細節。  

解題:
  [Lev1-Fallback](./Writeup/Clad/script/Lev1Sol.s.sol)

### 2024.08.31
學習內容:  
目標: 取得合約的所有權  
筆記:   
  - 如果要取得合約所有權，留意 owner = msg.sender 函式
  - 發現 有 owner = msg.sender 這段 code 是一個 public function
  - 呼叫 Fal1out() 取得合約所有權
此合約的問題和風險
  1. 拼寫錯誤的函數名稱 Fal1out()
  2. 沒有訪問控制權, 重要的操作只能由授權用戶執行, 例如使用 onlyOwner 來限制誰可以調用函式
       
解題:
  [Lev2-Fal1out](./Writeup/Clad/script/Lev2Sol.s.sol)

### 2024.09.02
學習內容:  
目標: 連續十次猜對擲硬幣的結果(flip() 執行十次都 return true)
卡關: 執行 code, 我的 consecutiveWins 只會累加到 1 就不會再往上增加......buging 中
筆記:   
  - 此 contract 有限制, 沒辦法在同一區塊執行多次, 所以要想辦法繞過, 能執行題目所說的 10 次
  - 要能讓 flip() 都 return true
此合約的問題和風險
  1. 區塊鍊的偽隨機問題
       
解題:
  [Lev2-Fal1out](./Writeup/Clad/script/Lev3Sol.s.sol)

### 2024.09.03
學習內容:  
目標: 取得合約的所有權
筆記:   
  - tx.orgin 代表最初發起這個交易的 EOA 的地址, 
此合約的問題和風險
  1. tx.orgin 進行權限檢查有安全風險, tx.origin 是原始用戶的地址, 攻擊者可能透過 tx.origin 調用目標合約的函數
解題:
  [Lev4-Phone](./Writeup/Clad/script/Lev4Sol.s.sol)
<!-- Content_END -->
