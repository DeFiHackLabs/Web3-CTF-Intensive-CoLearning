// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {MagicNum} from "../../src/Ethernaut/MagicNumber.sol";

interface Solver {
    function whatIsTheMeaningOfLife() external view returns (bytes32);
}

contract MagicNumberAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress);
        MagicNum magicNum = MagicNum(
            0x5AcDe5D61213eeaaf174EbF837b402B7C2AAf66D
        );
        Helper helper = new Helper();
        magicNum.setSolver(address(helper));
        address solver = magicNum.solver();
        bytes32 magic = Solver(solver).whatIsTheMeaningOfLife();
        vm.stopPrank();

        bool flag = true;
        if (
            magic !=
            0x000000000000000000000000000000000000000000000000000000000000002a
        ) {
            flag = false;
        }

        uint256 size;
        assembly {
            size := extcodesize(solver)
        }
        if (size > 10) {
            flag = false;
        }

        assertTrue(flag);
    }
}

contract Helper {
    constructor() {
        assembly {
            mstore(0, 0x602a60005260206000f3)
            return(0x16, 0x0a)
        }
    }
}
