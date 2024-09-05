# Delegation
## 題目
<img width="594" alt="截圖 2024-09-04 下午4 26 00" src="https://github.com/user-attachments/assets/e131223a-f73c-43b1-aba6-192dbb4225ad">

我們的目標是讓 `Delegation` 合約的 `owner` 變成我們的地址。這可以透過觸發 `delegatecall` 來實現，因為 `delegatecall` 的特性允許我們使用 `Delegate` 合約中的代碼，但將所有狀態變更儲存在 `Delegation` 合約中。

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```

### what is delegatecall?
1. **`call`**：
   - 當用戶A通過合約B來 `call` 合約C 時，執行的函數是合約C的，但語境（如變量和狀態）是合約C的。
   - 在這個情況下，`msg.sender` 是合約B，也就是發起調用的合約，並且狀態的改變將作用於合約C的變量上。
   - `call` 會在被調用的合約（合約C）中執行並更改其狀態。

![image](https://github.com/user-attachments/assets/fb6227fc-afed-431f-9b59-eb9b055479af)

2. **`delegatecall`**：
   - 當用戶A通過合約B來 `delegatecall` 合約C 時，執行的函數是合約C的，但語境仍然是合約B的。
   - 在這種情況下，`msg.sender` 是用戶A，因為 `delegatecall` 保持了原始的發起者，狀態的改變將作用於合約B的變量上，而不是合約C。
   - `delegatecall` 會使用合約C的邏輯，但會影響合約B的狀態，這是為什麼在使用 `delegatecall` 時必須保證兩個合約的變量存儲結構一致，否則可能導致不預期的錯誤。

![image](https://github.com/user-attachments/assets/9efa3e7a-31a9-4f42-8800-d829e665c62b)

所以當 `Delegation` 使用 `delegatecall` 調用 `Delegate` 的 `pwn()` 函式時，儘管 `pwn()` 修改的是 `owner` 變數，但實際變更的會是 `Delegation` 合約中的 `owner`。

## hack
- 直接呼叫 `pwn()` ， `owner` 就會變成自己了

<img width="595" alt="截圖 2024-09-04 下午4 45 03" src="https://github.com/user-attachments/assets/c95e0960-1f09-48eb-88a4-35d8ac7a6689">
