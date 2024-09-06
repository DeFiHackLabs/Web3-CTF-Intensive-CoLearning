---
timezone: Asia/Taipei
---


# Joy

1. 自我介绍
    對區塊鍊技術感興趣的初學者。
2. 你认为你会完成本次残酷学习吗？ 
    我可以的!!

## Notes

<!-- Content_START -->

### 2024.08.29

學習內容: 
- Ethernaut CTF - 01 Fallback:
- 目標：
  - 1. 成為合約owner
  - 2. 取走合約中所有的錢
  
- POC:
  - 分析
    - 合約中的receive function會將owner轉換為呼叫者，所以做到符合require的條件就可以成為合約owner
    - require
      - 條件一：msg.value > 0 (向合約地址轉eth)
      - 條件二：contributions[msg.sender] > 0 
  - 步驟

    1. 帶1 wei eth call contribute() 讓我的地址在contributions mapping結構有值(滿足receive function的require條件二)
    2. 帶1 wei eth call instance讓他觸發receive function，轉換合約ownership
    3. 最後call withdraw()取走所有的錢



  
### 2024.08.30
學習內容: 
- Ethernaut CTF - 02 Fallout:
- 目標：
  - 1. 成為合約owner
-  POC:
   - 分析
      -  合約中的constructor是一個public function，且在constructor可以取得合約owner的身份
   - 步驟
     - 呼叫Fallout function
  
  

<!-- Content_END -->
