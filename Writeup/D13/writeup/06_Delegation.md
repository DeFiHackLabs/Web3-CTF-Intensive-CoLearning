# 6 - Delegation

## 題目
[Delegation](https://ethernaut.openzeppelin.com/level/0x73379d8B82Fda494ee59555f333DF7D44483fD58)

### 通關條件
1. 這一關的目標是取得創建實例的所有權。

### 提示
1. 仔細看 solidity 文件關於 delegatecall 的低階函式。它是如何怎麽運行，如何委派操作給鏈上函式函式庫，以及它對執行時期作用範圍的影響
2. fallback 方法(method)
3. 方法(method)的 ID

## 筆記

- delegatecall 教學：[WTF Solidity极简入门: 23. Delegatecall](https://github.com/AmazingAng/WTF-Solidity/tree/main/23_Delegatecall)
- fallback可以參考 [level01 的 writeup](./01_Fallback.md)
- method ID: function 名稱 + 參數型態，like `transfer(address,uint256)`
- 目標是取得合約`Delegation`的所有權，但是合約本身除了建構之外沒有修改`owner`的方法。所以就要
delegatecall別的合約，也就是`Delegate`裡面的`pwn()`，但要如何透過`Delegation`去委託呢？`delegatecall`就放在`fallback()`裡面，底下附上合約的 fallback 原始碼：

``` Solidity
fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
        this;
    }
}
```

所以我們只要用 call 去調用合約就好 ([相關教學](https://github.com/AmazingAng/WTF-Solidity/tree/main/22_Call))，方法如下：

``` Solidity
address(level06).call(abi.encodeWithSignature("pwn()"));
```
