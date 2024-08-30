// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {IEthernaut} from "./IEthernaut.sol";
import "forge-std/Test.sol";

contract EthernautHelper is Script {
    address HERO = vm.envAddress("ACCOUNT_ADDRESS"); // NOTE CHANGE THIS INTO YOUR ADDRESS
    
    address constant ETHERNAUT = 0xa3e7317E591D5A0F1c605be1b3aC4D2ae56104d6;

    function createInstance(
        address levelAddress
    ) public returns (address challengeInstance) {
        require(HERO != address(0), "Set HERO address in EthernautHelper.sol");
        vm.recordLogs();
        IEthernaut(ETHERNAUT).createLevelInstance(levelAddress);
        Vm.Log[] memory createEntries = vm.getRecordedLogs();
        // This is the instance of the challenge contract you need to work with.
        challengeInstance = address(
            uint160(uint256(createEntries[0].topics[2]))
        );
    }

    function submitInstance(address challengeInstance) public returns(bool) {
        vm.recordLogs();
        IEthernaut(ETHERNAUT).submitLevelInstance(payable(challengeInstance));
        Vm.Log[] memory submitEntries = vm.getRecordedLogs();
        if (submitEntries.length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function successMessage(uint256 levelNo) public returns(string memory) {
        string memory message;

        string[] memory randMessages = new string[](7);
        randMessages[0] = "LEVEL SUCCESSFUL, GOOD JOB!";
        randMessages[1] = "LEVEL SUCCESSFUL, ANOTEHR ONE DONE!";
        randMessages[2] = "LEVEL SUCCESSFUL, KEEP IT UP!";
        randMessages[3] = "LEVEL SUCCESSFUL, GO GET 'EM TIGER!";
        randMessages[4] = "LEVEL SUCCESSFUL, YOU'RE A BEAST!";
        randMessages[5] = "LEVEL SUCCESSFUL, LET'S GOOO!";
        randMessages[6] = "LEVEL SUCCESSFUL, ANOTHER ONE BITES THE DUST!";
        
        if (levelNo == 1) {
            message = "LEVEL SUCCESSFUL, GOOD START!";
        } else if (levelNo == 10) { 
            message = "LEVEL SUCCESSFUL, 10 DOWN!";
        } else if (levelNo == 15) {
            message = "LEVEL SUCCESSFUL, PASSED THE HALFWAY MARK!";
        } else if (levelNo == 20) {
            message = "LEVEL SUCCESSFUL, 20 DOWN!";
        } else if (levelNo == 28) {
            message = "LEVEL SUCCESSFUL, JUST ONE LEFT!";
        } else if (levelNo == 29) {
            message = "LEVEL SUCCESSFUL, YOU DID IT!";
        } else {
            uint256 randMsgChoice = block.timestamp % randMessages.length;
            message = randMessages[randMsgChoice];
        }

        return message;
    }
    
    function _createInstance(
        address levelAddress
    ) public returns (address challengeInstance) {
        require(HERO != address(0), "Set HERO address in EthernautHelper.sol");
        vm.recordLogs();
        IEthernaut(ETHERNAUT).createLevelInstance(levelAddress);
        Vm.Log[] memory createEntries = vm.getRecordedLogs();
        // This is the instance of the challenge contract you need to work with.
        challengeInstance = address(
            uint160(uint256(createEntries[(createEntries.length-1)].topics[2]))
        );
    }

    function __createInstance(
        address levelAddress
    ) public returns (address challengeInstance) {
        require(HERO != address(0), "Set HERO address in EthernautHelper.sol");
        vm.recordLogs();
        IEthernaut(ETHERNAUT).createLevelInstance{value:0.001 ether}(levelAddress);
        Vm.Log[] memory createEntries = vm.getRecordedLogs();
        // This is the instance of the challenge contract you need to work with.
        challengeInstance = address(
            uint160(uint256(createEntries[0].topics[2]))
        );
    }
}
