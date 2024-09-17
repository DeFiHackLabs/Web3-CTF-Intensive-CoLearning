// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {DamnValuableToken} from "../DamnValuableToken.sol";
import {L1Forwarder} from "../withdrawal/L1Forwarder.sol";

contract TokenBridge {
    DamnValuableToken public immutable token;
    L1Forwarder public immutable l1Forwarder;
    address public immutable otherBridge;

    uint256 public totalDeposits;

    error Unauthorized();

    constructor(DamnValuableToken _token, L1Forwarder _forwarder, address _otherBridge) {
        token = _token;
        l1Forwarder = _forwarder;
        otherBridge = _otherBridge;
    }

    function executeTokenWithdrawal(address receiver, uint256 amount) external {
        if (msg.sender != address(l1Forwarder) || l1Forwarder.getSender() == otherBridge) revert Unauthorized();
        totalDeposits -= amount;
        token.transfer(receiver, amount);
    }

    /**
     * functions for deposits and that kind of bridge stuff
     * [...]
     */
}
