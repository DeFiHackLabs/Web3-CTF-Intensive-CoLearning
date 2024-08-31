# 4 - Telephone

## 題目
[Telephone](https://ethernaut.openzeppelin.com/level/0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446)

### 通關條件
1. 取得合約的所有權

## 筆記
- 了解`tx.origin`跟`msg.sender`的差別：[The difference between tx.origin and msg.sender in Solidity, and how it changes with account abstraction](https://medium.com/@natelapinski/the-difference-between-tx-origin-60737d3b3ab5)
- 相關攻擊教學：[WTF Solidity 合约安全: S12. tx.origin钓鱼攻击](https://github.com/AmazingAng/WTF-Solidity/blob/main/S12_TxOrigin/readme.md)
- 寫一個 script 呼叫另一個合約，合約再去呼叫`changeOwner()`就可以取得所有權了
