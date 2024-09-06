# 05 - Token writeup

## 题目
[Token](https://ethernaut.openzeppelin.com)

题目如下
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
```

## 解题
在Solidity 0.6.0版本中，uint256类型如果发生下溢，会回绕到最大值。
例如，如果我们有20个代币，尝试转出21个，20 - 21会变成一个非常大的数字（2^256 - 1），这会使transfer函数调用后，没有减少代币，而是增加了代币。

所以，在console 输入 await contract.transfer("0x7AE87cf24Fb5096182a969a1Ad45D0c54410d1Ca",21) , 会因为下溢而使代币数
变为非常的大，此时完成了题目要求。
