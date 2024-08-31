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
  [Lev1-Fallback](./Writeup/Clad/Lev1Sol.s.sol)

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
  [Lev2-Fal1out](./Writeup/Clad/Lev2Sol.s.sol)

<!-- Content_END -->
