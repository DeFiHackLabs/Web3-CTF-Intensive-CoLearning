---
timezone: Asia/Taipei
---

# {Clad}

1. Hello World
2. 你认为你会完成本次残酷学习吗？我用盡全力

## Notes

<!-- Content_START -->

### 心得
- foundry 和 solidity 零經驗, 目前寫到 Ethernaut 第六題, 幾乎都要看著解答才寫得出來
- 目前至少會在本地跑 foundry 環境, 並讓 code 跑起來
- 目前嘗試邊寫 Ethernaut, 邊學習 solidity 基礎

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
  - tx.orgin 代表最初發起這個交易的 EOA 的地址 
此合約的問題和風險
  1. tx.orgin 進行權限檢查有安全風險, tx.origin 是原始用戶的地址, 攻擊者可能透過 tx.origin 調用目標合約的函數
解題:
  [Lev4-Phone](./Writeup/Clad/script/Lev4Sol.s.sol)

### 2024.09.04
學習內容:  
目標: 增加手中代幣的數量
筆記:   
  -  solidity 版本為 0.6.0, 可以留意數字運算邏輯, 檢查相減是否小於0, 相加是否超過位元上限
此合約的問題和風險
  1. underflow
解題:
  [Lev5-Token](./Writeup/Clad/script/Lev5Sol.s.sol)

### 2024.09.06
學習內容:  
目標: 取得合約所有權
筆記:   
  - delegatecall, 本地合約調用其他合約的一種 low-level 方法
  - 使用 delegatecall 要注意兩個合約之間的狀態變數數量, 型態, 順序是否都相同
  - function selector, 對 function signature 做 hash(keccak-256) 後取前四個 bytes
  - abi.encode 可以將 input 參數按照一定的規則轉換成 bytes 格式, 經 ABI 編碼後的程式才能在合約之間進行互動, abi.encodeWithSignature
此合約的問題和風險
  1. Delegation 合約找不到對應的 function selector 而進入 fallback function, 讓 delagatecall 呼叫 Delegate 合約的 pwn()
解題:
  [Lev6-Delegation](./Writeup/Clad/script/Lev6Sol.s.sol)

### 2024.09.07
學習內容:  
目標: 讓合約餘額大於 0
筆記:   
  - selfdestruct
  - selfdestruct(address payable recipient)
  - 因為目標合約甚麼都沒有, 也無功能使用, 所以另建一個合約, 把原合約用 selfdestruct 後, 並給 1wei 讓合約大於 0
解題:
  [Lev7-Force](./Writeup/Clad/script/Lev7Sol.s.sol)

### 2024.09.09
學習內容:  
目標: 取得合約的密碼
筆記:   
  - 透過 etherscan 嘗試查詢合約的密碼
  - 透過 cast storage 合約地址取得密碼
  - 透過 hex to string 可以破解密碼
此合約的問題和風險
  1.因為區塊鏈上的資訊公開透明, 所以不能把密碼寫在合約裡, 有被破解的風險
解題:
  [Lev8-Vault](./Writeup/Clad/script/Lev8Sol.s.sol)

### 2024.09.10
學習內容:  
目標: 1.成為合約的 King 2.讓其他人無法成為 King, 也就是 DOS 這個合約
筆記:   
  - DOS 在一定的時間內或永久讓合約無法運行原有功能
卡關: 大概知道要另寫一個攻擊合約, call value 並給 >= prize, 但要給多少, 即便成功大於 prize 也是成為king, 要怎麼讓合約失效
此合約的問題和風險
解題:
  [Lev9-King](./Writeup/Clad/script/Lev9Sol.s.sol)

### 2024.09.12
學習內容:  
目標: 1.偷走合約所有的資產
筆記:   
  - re entrancy 步驟
  - 呼叫 donate(), 往合約打入資金
  - 呼叫 withdraw(), 提取資金, 順便透過 msg.sender.call 觸發你的攻擊合約
  - 呼叫 receive(), 再次 withdraw() 提取資金
  - 重複直到湖約的餘額小於 0
    
卡關: 流程有點複雜, 程式的執行順序還需要再釐清  
  1.withdraw function 沒有先更新合約的餘額狀態, 就先與外部的合約互動進行轉帳, 會有 re-entrancy 風險
解題:
  [Lev10-Reentrace](./Writeup/Clad/script/Lev10Sol.s.sol)

### 2024.09.13
題目: Elvator  
學習內容  
目標: 讓合約的電梯能達到頂樓, bool top = true  
此合約的問題和風險: 合約的 external call 錯誤運用, 呼叫同一個 external call 兩次卻能得到不同回傳結果  
筆記:     
解題:  
  [Lev11-Elvator](./Writeup/Clad/script/Lev11Sol.s.sol)

### 2024.09.14
題目: Privacy    
學習內容      
目標: 解鎖合約, 把 locked 狀態改為 false  
筆記:     
    - 要會算每個變數的大小, 按規則寫入 slot
    - 題目 unlock() 要與 key 判斷的 data[2] 在 slot 5
    - cast storage 題目實例, 取得 key
    - 照著題目把 key 轉換成 bytes32, 再轉成 bytes16 餵入 unlock()
解題:  
  [Lev12-Privacy](./Writeup/Clad/script/Lev12Sol.s.sol)  

### 2024.09.17
題目: GateKeeperOne      
學習內容      
目標: 滿足題目的三個 function 條件
      1.msg.sender != tx.origin
      2.當前的 gas 數量能被 8191 整除
      3.能在 uint, bytes, address 之間轉換, 會用到 type casting
筆記:     
    - tx.origin 是 EOA, msg.sender 可以是合約, 所以用合約呼叫, 不是用 EOA  
    - 用 .call{gas: amount} 控制 external call 使用的 gas 量, 每一個 external call 最低 gas 是 21000, 所以用迴圈 .call{gas: i + 8191 * 3} 去跑看能否被 8191 整除  
    - 第三關複雜了, 到目前還是看不太懂, 可能要先把 type casting 觀念釐清  
問題:  
    - 還要再熟悉 function run() 裡面呼叫自己額外寫合約的寫法
    - 為什麼 .call{gas: 8191*3} 就好, 還要跑迴圈  
解題:      
  [Lev13-GatekeeperOne](./Writeup/Clad/script/Lev13Sol.s.sol)  
  
<!-- Content_END -->
