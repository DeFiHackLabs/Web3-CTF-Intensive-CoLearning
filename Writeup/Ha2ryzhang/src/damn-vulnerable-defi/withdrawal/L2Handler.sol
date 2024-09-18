// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {L1Forwarder} from "./L1Forwarder.sol";
import {L2MessageStore} from "./L2MessageStore.sol";

/**
 * @notice This contract is not deployed in the challenge.
 *         We just include it for you to understand how the withdrawal logs were created. 
 */
contract L2Handler {
    L2MessageStore public immutable l2MessageStore;
    uint256 public nonce;
    L1Forwarder public immutable l1Forwarder;

    constructor(L2MessageStore _l2MessageStore, L1Forwarder _l1Forwarder) {
        l2MessageStore = _l2MessageStore;
        l1Forwarder = _l1Forwarder;
    }

    function sendMessage(address target, bytes calldata message) external {
        l2MessageStore.store({
            target: address(l1Forwarder),
            data: abi.encodeCall(L1Forwarder.forwardMessage, (nonce, msg.sender, target, message))
        });

        unchecked {
            nonce++;
        }
    }
}
