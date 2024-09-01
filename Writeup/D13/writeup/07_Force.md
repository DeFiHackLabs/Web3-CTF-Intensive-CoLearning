# 7 - Force

## 題目
[Force](https://ethernaut.openzeppelin.com/level/0xb6c2Ec883DaAac76D8922519E63f875c2ec65575)

### 通關條件
1. 這一關的目標是使合約的餘額大於 0

### 提示
1. fallback 方法
2. 有時候攻擊一個合約最好的方法是使用另一個合約

## 筆記

- fallback可以參考 [level01 的 writeup](./01_Fallback.md)
- 沒有 `receive()` 和 `fallback()` 函數，直接轉錢會失敗
- 自毀合約會觸發把合約剩餘以太轉到指定地址，詳細可看 [WTF Solidity极简入门: 26. 删除合约
](https://github.com/AmazingAng/WTF-Solidity/tree/main/26_DeleteContract)
- 寫一個script呼叫一個合約，那個合約在創建時就會自毀，並把餘額轉到題目