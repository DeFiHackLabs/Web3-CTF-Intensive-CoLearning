// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "Ethernaut/gatekeeperthree_poc.sol";

contract GatekeeperThreePocScript is Script {
    function run() public {
      uint256 deployerKey = vm.envUint("PRIVATE_KEY");
      vm.startBroadcast(deployerKey);

      GatekeeperThreePoc gatekeeperThreePoc = GatekeeperThreePoc(payable(0x778915D713BDD68d51f2beD54c58E0C442B65de0));
      gatekeeperThreePoc.exploit{value: 0.002 ether}();
      vm.stopBroadcast();
    }
}