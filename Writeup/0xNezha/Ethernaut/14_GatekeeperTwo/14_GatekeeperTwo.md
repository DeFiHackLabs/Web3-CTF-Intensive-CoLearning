### 第14关：Gatekeeper Two 

这一关同样有3个 modifier 在前面把着门，我们需要同时满足这三个条件：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;
    // 1.要求调用者不是交易的发起者。需要通过合约来调用 
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }
    // 2.要求调用者的 extcodesize 为 0, 需要将操作放置在 constructor() 中，使得合约部署前就完成攻击操作
    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }
    // 3. 通过异或运算，求出 _gateKey。例如运用异或运算的自反性 a ^ b ^ a = b
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