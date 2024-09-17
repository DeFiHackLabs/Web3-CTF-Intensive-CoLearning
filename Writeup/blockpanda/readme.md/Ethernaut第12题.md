### 第十二题 Privacy
### 题目
这个合约的制作者非常小心的保护了敏感区域的 storage.解开这个合约来完成这一关.
### 提示
- 理解 storage 的原理
- 理解 parameter parsing 的原理
- 理解 casting 的原理
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;
    //ID，其值为合约部署时的时间戳
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    //awkwardness，其值为合约部署时的时间戳转换为16位整数。
    uint16 private awkwardness = uint16(block.timestamp);
    //私有的32字节数组data，长度为3
    bytes32[3] private data;
    //接受一个32字节数组_data作为参数，并将其赋值给私有变量data
    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
    //检查传入的_key是否等于data数组的第三个元素的前16字节。如果条件不满足，函数会抛出异常并停止执行。
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
### 解题思路
和第八题类似，只要获取找到data[2]的值，然后传给unlock函数的key，就可以了
这里locked在slot0,ID在slot1,flatteningh和denomination/awkwardness在slot2,data[0]-slot3,data[1]-slot4,data[2]-slot5
### 解题过程
1. await web3.eth.getStorageAt("合约地址",5)  //获取slot内的数据
2. contract.unlock(前16位)
3. 提交
