# Vault
## 題目

這個關卡的目標是利用 `unlock()` 函數來解鎖 `Vault` 合約
## 合約

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;
  
    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }
  
    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
```

這個合約有兩個狀態變數：
1. `locked`: 一個布林值，用來表示金庫是否被鎖住。
2. `password`: 一個私有的 `bytes32` 型態變數，作為解鎖金庫的密碼。

`unlock()` 函數會檢查傳入的 `_password` 是否與存儲的 `password` 相同，若相同則將 `locked` 設為 `false`，解鎖金庫。

### 如何找到 `password`

`password` 是一個 `private` 變數，雖然無法直接調用合約來讀取它，但由於區塊鏈上的數據都是公開的，所以我們可以通過讀取合約的 storage 來提取這個變數的值。

### Solidity Storage Slot

在 Solidity 中，每個合約的狀態變數都存儲在以 slot 為單位的永久存儲中，每個 slot 可以存儲 32 bytes (256 bits) 的資料。這些 slot 是根據變數宣告的順序和大小來分配的。

根據合約變數的順序和大小，我們可以推斷變數會存在哪個 slot 中：
1. **`locked`** 是一個 `bool`，佔用 1 byte，存儲在 slot 0 中。
2. **`password`** 是一個 `bytes32`，佔用完整的 32 bytes，因此會存儲在 slot 1 中。

## hack

- 讀取 `password`

```javascript
await web3.eth.getStorageAt(contract.address, 1)
```
> 我們在題目的主控台可以利用這個來獲取 slot 1 ，也就是 password 的直。

- 調用 `unlock()` 函數來解鎖合約，將 `locked` 狀態設為 `false`
