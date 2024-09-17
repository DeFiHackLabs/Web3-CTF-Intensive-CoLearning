# 16 - Preservation

## 题目
攻击以下合约
```solidity
//A contract creator has built a very simple token factory contract. Anyone can create new tokens with ease. After deploying the first token contract, the creator sent 0.001 ether to obtain more tokens. They have since lost the contract address.
//
//This level will be completed if you can recover (or remove) the 0.001 ether from the lost contract address.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
//generate tokens
function generateToken(string memory _name, uint256 _initialSupply) public {
new SimpleToken(_name, msg.sender, _initialSupply);
}
}

contract SimpleToken {
string public name;
mapping(address => uint256) public balances;

// constructor
constructor(string memory _name, address _creator, uint256 _initialSupply) {
name = _name;
balances[_creator] = _initialSupply;
}

// collect ether in return for tokens
receive() external payable {
balances[msg.sender] = msg.value * 10;
}

// allow transfers of tokens
function transfer(address _to, uint256 _amount) public {
require(balances[msg.sender] >= _amount);
balances[msg.sender] = balances[msg.sender] - _amount;
balances[_to] = _amount;
}

// clean up after ourselves
function destroy(address payable _to) public {
selfdestruct(_to);
}
}
```

## 解题
本题考察点：
1.需要在链上找到题目合约的链上记录，也就是题目生成币的交易记录，可以通过 holesky.etherscan.io 找到 Internal Transactions
 选项中查看。
2.调用 destroy 将找到的合约余额发送给自己。




