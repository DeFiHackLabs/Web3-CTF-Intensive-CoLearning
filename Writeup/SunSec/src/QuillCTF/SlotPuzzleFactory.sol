// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SlotPuzzle} from "./SlotPuzzle.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import "./interface/ISlotPuzzleFactory.sol";

contract SlotPuzzleFactory is ReentrancyGuard{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeTransferLib for address;

    EnumerableSet.AddressSet deployedAddress;

    constructor() payable {
        require(msg.value == 3 ether);
    }

    function deploy(Parameters calldata params) external nonReentrant {
        SlotPuzzle newContract = new SlotPuzzle();

        deployedAddress.add(address(newContract));   
        newContract.ascertainSlot(params); 
    }

    function payout(address wallet,uint256 amount) external {
        require(deployedAddress.contains(msg.sender));
        require(amount == 1 ether);
        wallet.safeTransferETH(amount);
    }   
}
