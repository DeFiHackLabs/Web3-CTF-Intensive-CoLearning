// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Privacy.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 解鎖合約, 把 locked 狀態改為 false

contract Lev11Sol is Script {
    Privacy public lev12Instance =
        Privacy(0xCC40ce54E5b5DA5d09EF4440F013c55333DE28d1);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        bytes32 key = 0x606e04fcac62ff1404e4f5079a5f78110f47aadb87192ef7f7de94d24b8e5935;
        lev12Instance.unlock(bytes16(key));

        vm.stopBroadcast();
    }
}
