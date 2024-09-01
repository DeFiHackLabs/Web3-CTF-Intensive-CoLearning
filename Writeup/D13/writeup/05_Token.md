# 5 - Token

## 題目
[Token](https://ethernaut.openzeppelin.com/level/0x478f3476358Eb166Cb7adE4666d04fbdDB56C407)

### 通關條件
1. 你一開始會被給 20 個代幣。如果你找到方法增加你手中代幣的數量，你就可以通過這一關，當然代幣數量越多越好。

### 提示
1. 什麽是 odometer?

## 筆記

- odometer 是指汽車的里程表，假設達到最大值後再+1便會歸零，就是overflow的問題
- 了解 solidity 每個型態的數值範圍 (0.8.0以後多了Safemath庫，可避免這種問題)
- 相關攻擊教學：[WTF Solidity 合约安全: S05. 整型溢出](https://github.com/AmazingAng/WTF-Solidity/blob/main/S05_Overflow/readme.md)

``` Solidity
mapping(address => uint256) balances;

function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
}
```
- 這題重點就是這個 function，看起來功能是轉代幣給別人，但就像提示給的overflow一樣，我們原本手上有20個代幣，儲存代幣數量的型態是`uint256`，範圍是 $0 \text{ 到 } 2^{256}-1$，並沒有負數，所以我們只要轉出去 21 個代幣就可以讓貨幣數量變成最大