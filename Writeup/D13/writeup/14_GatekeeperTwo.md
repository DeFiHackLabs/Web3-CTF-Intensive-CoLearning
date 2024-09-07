# 14 - Gatekeeper Two

## 題目
[Gatekeeper Two](https://ethernaut.openzeppelin.com/level/0x0C791D1923c738AC8c4ACFD0A60382eE5FF08a23)

### 通關條件
1. 守衛帶來了一些新的挑戰，同樣地，你需要注冊為參賽者才能通過這一關。

### 提示
1. 回想一下你從上一個守衛那學到了什麽，第一道門是一樣的
2. 第二道門的 `assembly` 關鍵字可以讓合約去存取 Solidity 非原生的功能。參見 [Solidity Assembly](http://solidity.readthedocs.io/en/v0.4.23/assembly.html)。在這道門的 `extcodesize` 函式，可以用來得到給定地址的合約程式碼長度，你可以在[黃皮書](https://ethereum.github.io/yellowpaper/paper.pdf)的第七章學到更多相關的資訊。
3. `^` 字元在第三個門裡是位元運算 (XOR)，在這裡是為了應用另一個常見的位元運算手段 (參見 [Solidity cheatsheet](http://solidity.readthedocs.io/en/v0.4.23/miscellaneous.html#cheatsheet))。Coin Flip 關卡也是一個想要破這關很好的參考資料。

## 筆記
- `assembly` 的重點就是可以在合約裡直接操作 opcode，在 EVM 中 opcode (操作碼) 就是比 solidity 更底層的語言。`assembly` 可以讓你直接使用這些操作碼提升效能並降低 gas 費用；缺點是沒有安全性的檢查或是容易發生一些意外的錯誤
- 這邊提到使用 `extcodesize` 函式，這個函式會回傳輸入地址的合約程式碼長度，正常情況下可以用來判斷這個地址是合約還是 EOA。  
這邊問題就來了，為了通過第一關的 `require(msg.sender != tx.origin);`，我們必須呼叫另一個合約，但是第二個條件又規定互叫合約的地址程式碼必須等於 0 ，這邊帶出另一個觀念：當一個合約要被部署的時候會被轉成 bytecode，其中會把 function 分成 **Creation** 跟 **Runtime**，用途如下：
  - Creation
    - 用途：**Creation** 儲存創建合約時會用到的 `constructor()`。它在合約創建過程中被執行，主要負責初始化合約的狀態和變數設定。
    - 特點：這部分的 code 在合約部署時會被執行一次，完成合約的部署和初始化。執行完畢後，這部分會被移除，也就是說不會被儲存在區塊中。
  - Runtime
    - 用途：**Runtime** 儲存合約部署後實際執行的 function。它處理合約的函數調用和邏輯運算。
    - 特點：部署完成後，**Creation** 會被清除，只留下 **Runtime**。合約的所有交互和狀態更新都是通過這部分來完成的。
  - 詳細可以參考以下兩篇：
    - [[EN] Deconstructing a Solidity Contract - Part II: Creation vs. Runtime](https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-ii-creation-vs-runtime-6b9d60ecb44c)
    - [[中文] 深入解析Solidity合約](https://medium.com/taipei-ethereum-meetup/%E6%B7%B1%E5%85%A5%E8%A7%A3%E6%9E%90solidity%E5%90%88%E7%B4%84-4213c8c7dfa0)

  看完上面後，就可以知道要達成第二個條件：`extcodesize(caller()) == 0`，只要把攻擊都實作在 `constructor()` 中就可以了()
- 第三個條件只要熟 XOR 運算就很簡單，這邊使用 xor 的特性： A^B = C, A^C = B
- 綜合上述，這題的攻擊合約重點：
  1. 呼叫另一個攻擊合約
  2. 攻擊實作在 `constructor()` 中
  3. `_gateKey = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;`