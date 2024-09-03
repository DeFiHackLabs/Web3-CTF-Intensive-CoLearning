# 10 - Re-entrancy

## 題目
[Re-entrancy](https://ethernaut.openzeppelin.com/level/0x2a24869323C0B13Dff24E196Ba072dC790D52479)

### 通關條件
1. 這一關的目標是偷走合約的所有資產

### 提示
1. 沒被信任的(untrusted)合約可以在你意料之外的地方執行程式碼
1. fallback 方法
1. 拋出(throw)/恢復(revert) 的通知
1. 有的時候攻擊一個合約的最好方式是使用另一個合約
1. 查看上方幫助頁面 "Beyond the console" 章節

## 筆記

- [WTF Solidity 合约安全: S01. 重入攻击](https://github.com/AmazingAng/WTF-Solidity/tree/main/S01_ReentrancyAttack)
- 經典的智能合約漏洞
- 關於第一個提示真的是給開發合約的人看的，跟任何合約互動或串接都一定要看清楚每個函數的處理跟錯誤處理。
- 主要思路就是寫一個合約去提款，提款就會觸發合約的 `receive()` ，再去撰寫惡意的receive function即可通關