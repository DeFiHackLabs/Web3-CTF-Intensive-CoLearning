// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Start} from "src/Start.sol";

contract StartScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        Start start = new Start();
        string memory world = start.hello("OZCTF{0N3_G14NT_L3AP_F0R_M4NK1ND}");
        console.log(world);
    }
}
