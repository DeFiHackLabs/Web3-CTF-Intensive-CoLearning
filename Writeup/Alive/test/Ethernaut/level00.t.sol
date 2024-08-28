// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Level00} from "../../src/Ethernaut/level00.sol";

contract ContractTest is Test {
    function setUp() public {}

    function testExploit() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
        Level00 level00 = Level00(0x044dD753634CaAa34c6F051D5A245e82bB65E4Fd);
        playerScript(level00);
        assertTrue(level00.getCleared());
    }
}

function playerScript(Level00 instance) {
    instance.authenticate(instance.password());
}
