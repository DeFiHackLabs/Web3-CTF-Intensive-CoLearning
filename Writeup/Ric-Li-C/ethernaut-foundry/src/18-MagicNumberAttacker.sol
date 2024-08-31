// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract MagicNumberAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        /** 
         * Another answer: "\x69\x60\x2a\x60\x00\x52\x60\x20\x60\x00\xf3\x60\x00\x52\x60\x0a\x60\x16\xf3"
         */
        bytes memory code = "\x60\x0a\x60\x0c\x60\x00\x39\x60\x0a\x60\x00\xf3\x60\x2a\x60\x80\x52\x60\x20\x60\x80\xf3";
        address solver;
        assembly {
            solver := create(0, add(code, 0x20), mload(code))
        }
        MagicNum(challengeInstance).setSolver(solver);
    }
}


contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }
}