// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct Recipients{
    address account;
    uint256 amount;
}

struct Parameters{
    uint256 totalRecipients;
    uint256 offset;
    Recipients[] recipients;
    bytes slotKey;
}

interface ISlotPuzzleFactory {
    function payout(address wallet,uint256 amount) external;
    function ascertainSlot(Parameters calldata params) external returns (bool status);
}
