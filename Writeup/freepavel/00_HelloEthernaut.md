### Hello Ethernaut
第一題可以應該就是告訴大家如何跟這邊的合約做交互
![截圖 2024-08-29 下午1.54.56](https://hackmd.io/_uploads/SyRV6F6sC.png)
連接錢包之後會拿到 level address, Player address(連接的錢包地址), Ethernuat address, Instance address
![截圖 2024-08-29 下午1.56.05](https://hackmd.io/_uploads/SyfKpKpjR.png)
之後就依照指示在主控台打指令
![截圖 2024-08-29 下午1.56.32](https://hackmd.io/_uploads/r1yjTtpiA.png)
![截圖 2024-08-29 下午1.57.02](https://hackmd.io/_uploads/H1oh6tToA.png)
![截圖 2024-08-29 下午1.57.17](https://hackmd.io/_uploads/Byuaptps0.png)
![截圖 2024-08-29 下午1.57.41](https://hackmd.io/_uploads/rJGJ0KTi0.png)
```javascript
contract.info()
contract.info1()
contract.info2()
contract.theMethodName()
contract.method7123949()
contract.password()
contract.authenticate("ethernaut0")
```
![截圖 2024-08-29 下午1.58.01](https://hackmd.io/_uploads/ryFeRt6sA.png)


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Instance {
    string public password;
    uint8 public infoNum = 42;
    string public theMethodName = "The method name is method7123949.";
    bool private cleared = false;

    // constructor
    constructor(string memory _password) {
        password = _password;
    }

    function info() public pure returns (string memory) {
        return "You will find what you need in info1().";
    }

    function info1() public pure returns (string memory) {
        return 'Try info2(), but with "hello" as a parameter.';
    }

    function info2(string memory param) public pure returns (string memory) {
        if (keccak256(abi.encodePacked(param)) == keccak256(abi.encodePacked("hello"))) {
            return "The property infoNum holds the number of the next info method to call.";
        }
        return "Wrong parameter.";
    }

    function info42() public pure returns (string memory) {
        return "theMethodName is the name of the next method.";
    }

    function method7123949() public pure returns (string memory) {
        return "If you know the password, submit it to authenticate().";
    }

    function authenticate(string memory passkey) public {
        if (keccak256(abi.encodePacked(passkey)) == keccak256(abi.encodePacked(password))) {
            cleared = true;
        }
    }

    function getCleared() public view returns (bool) {
        return cleared;
    }
}
```
