# 11 - Elevator

## 题目
攻击以下合约
```
这个守门人带来了一些新的挑战, 同样的需要注册为参赛者来完成这一关

这可能有帮助:
想一想你从上一个守门人那学到了什么.
第二个门中的 assembly 关键词可以让一个合约访问非原生的 vanilla solidity 功能. 参见 Solidity Assembly . extcodesize 函数可以用来得到给定地址合约的代码长度 - 你可以在这个页面学习到更多 yellow paper.
^ 符号在第三个门里是位操作 (XOR), 在这里是代表另一个常见的位操作 (参见 Solidity cheatsheet). Coin Flip 关卡也是一个很好的参考.
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

## 解题
本题考察几点： 
1.需要通过合约调用合约
2.需要在 constract 构造中调用 enter ，此时合约中尚无任何代码数据
3. a ^ b = c  a ^ c = b   a 是合约地址的最后8字节 b是0xFFFFFFFFFFFFFFFF c是需要传入的参数
代码如下：
```solidity


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface GatekeeperTwo {
     function enter(bytes8) external  returns (bool);
}

contract hackGatekeeperOne {
    GatekeeperTwo Gatekeepercontract ;
    constructor(address addr) {
        Gatekeepercontract = GatekeeperTwo(addr);
        bytes8 key =  bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this)))))) ^   ;
        Gatekeepercontract.enter(key) ;
    }
```
为什么 bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ uint64(0xffffffffffffffff));中 bytes8 与 uint64可以 用 xor

为什么 bytes8 和 uint64 可以进行异或（XOR）操作：
数据表示：
bytes8 和 uint64 都是 64 位（8 字节）的数据类型。
在底层，它们都是以 64 位二进制形式存储的。
类型转换：
Solidity 允许在 bytes8 和 uint64 之间进行隐式转换。
这种转换不会改变底层的二进制表示。
3. 位操作：
   XOR（^）是一个位级操作，它对两个操作数的每一位进行操作。
   无论数据类型是 bytes8 还是 uint64，XOR 操作都是在它们的二进制表示上进行的。
   操作过程：
   ;
- 这里，a 首先被转换为 uint64，然后与 b 进行 XOR 操作。
  为什么使用 type(uint64).max：
  type(uint64).max 等同于 0xffffffffffffffff。
  这个值的每一位都是 1。
  与任何值进行 XOR 操作都会得到该值的位反转结果。
  在给定的表达式中：
  )
- keccak256(...) 生成一个 32 字节的哈希。
  bytes8(...) 取这个哈希的前 8 字节。
  uint64(...) 将这 8 字节转换为 uint64。
  然后与 0xffffffffffffffff 进行 XOR 操作。
  最后结果再转回 bytes8。
7. 安全性考虑：
   这种操作在密码学中常用于混淆或解混淆数据。
   在这个合约中，它用于创建一个满足特定条件的密钥。
   总结：
   bytes8 和 uint64 可以进行 XOR 操作是因为它们在底层都是 64 位二进制数，Solidity 允许它们之间的隐式转换，而 XOR 操作是在位级别进行的，不受数据类型的表面差异影响。这种技巧在智能合约中经常用于创建复杂的逻辑或满足特定的密码学要求。