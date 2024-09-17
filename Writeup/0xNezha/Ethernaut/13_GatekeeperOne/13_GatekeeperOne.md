### 第13关：Gatekeeper One 

这一关有3个 modifier 在前面把着门，我们需要同时满足这三个条件：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;
    // 条件1：目标合约的调用者不能是本次交易的发起者。解决方案：部署一个合约来调用目标合约
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }
    // 条件2：执行到 gateTwo() 的时候，剩余的 gas 应该是 8191 的整数倍。
    // 可以通过 Debug 去查看执行到这里用了多少 gas ，也可以估算大致的范围，然后循环累加去尝试。
    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }
    // 这里牵涉到一系列数据类型转换，我们要知道 EVM 是栈虚拟机，采用的是大端模式，所以：
    // 传入长度为 8字节 的字节数组，假设是 【0x1122334455667788】
    modifier gateThree(bytes8 _gateKey) {
        // uint64转uint32, 只保留低32位部分, 即 0x55667788
        // uint64转uint16, 只保留低16位部分, 即 0x7788
        // 要求1：key 的低 32位（最后4个字节） == key 的低 16位，也就是说 key 的 77 的位置应该是 “00”
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        // 要求2：key 的低 32位（最后4个字节） != key 的低 64位, 也就是说 key 的 5566 的位置不能是 “0000”
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        // 要求3：key 的低 32位（最后4个字节） == 交易发起者地址的最后4个字节
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
关于 gateTwo ，如果采取循环累加 gas 的方式去猜，可以这样暴破：

```solidity
contract attack {
    ...
    function exploit() public {
        bytes8 key=0x1122334455667788;
        bool result;
        for (uint256 i = 0; i < 150; i++) {
            (bool result, bytes memory data) = address(target).call{gas:i + 150 + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)",key));
            if (result) {
                break;
            }
        }
    ...
    }

}

```

附：数据类型转换参考
```solidity
contract Test {
    //
    bytes8  public b8  = 0x1122334455667788;
    bytes4  public b4  =  bytes4(b8);  // 0x11223344
    bytes16 public b16 =  bytes16(b8); //0x11223344556677880000000000000000

    uint32 public u32 = 0x11223344;
    uint16 public u16 = uint16(u32); //0x3344
    uint64 public u64 = uint32(u32); //0x0000000011223344
}
```