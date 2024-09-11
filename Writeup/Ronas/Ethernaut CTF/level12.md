# Ethernaut CTF Writeup

## Level 12 Privacy

> 題目: https://ethernaut.openzeppelin.com/level/0x39DFCa77F257423621f9fb8a248cb6E3EaDb5016

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;              // 1 byte - slot 0
    uint256 public ID = block.timestamp;    // 32 byte - slot 1
    uint8 private flattening = 10;          // 1 byte - slot 2
    uint8 private denomination = 255;       // 1 byte - slot 2
    uint16 private awkwardness = uint16(block.timestamp); // 2 byte - slot 2
    bytes32[3] private data;                // 3*32 byte - slot 3-5

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

過關條件: 

- 這個合約的開發者非常小心的保護了 storage 敏感資料的區域.
- 把這個合約解鎖就可以通關喔！

解法：

- 解析各變數型別後，可發現機密的 `data[2]` 會在 slot 5 (`data[0]`: slot 3, `data[1]`: slot 4)
- 讀取 slot 5 讀出 `data[2]` 的值 `web3.eth.getStorageAt(contract.address, 5)` = `0xc4c8520a8854b569ae7778c24a6ecb3e4f43f038d0ac55e79427d45931b8fea9`
- `bytes16(0xc4c8520a8854b569ae7778c24a6ecb3e4f43f038d0ac55e79427d45931b8fea9)` = `0xc4c8520a8854b569ae7778c24a6ecb3e`
- 解鎖 `contract.unlock("0xc4c8520a8854b569ae7778c24a6ecb3e")`
- 確認解鎖狀態 `contract.locked()`

```

```