// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {L1Gateway} from "./L1Gateway.sol";

contract L1Forwarder is ReentrancyGuard, Ownable {
    using Address for address;

    mapping(bytes32 messageId => bool seen) public successfulMessages;
    mapping(bytes32 messageId => bool seen) public failedMessages;

    L1Gateway public gateway;
    address public l2Handler;

    struct Context {
        address l2Sender;
    }

    Context public context;

    error AlreadyForwarded(bytes32 messageId);
    error BadTarget();

    constructor(L1Gateway _gateway) {
        _initializeOwner(msg.sender);
        gateway = _gateway;
    }

    function setL2Handler(address _l2Handler) external onlyOwner {
        l2Handler = _l2Handler;
    }

    function forwardMessage(uint256 nonce, address l2Sender, address target, bytes memory message)
        external
        payable
        nonReentrant
    {
        bytes32 messageId = keccak256(
            abi.encodeWithSignature("forwardMessage(uint256,address,address,bytes)", nonce, l2Sender, target, message)
        );

        if (msg.sender == address(gateway) && gateway.xSender() == l2Handler) {
            require(!failedMessages[messageId]);
        } else {
            require(failedMessages[messageId]);
        }

        if (successfulMessages[messageId]) {
            revert AlreadyForwarded(messageId);
        }

        if (target == address(this) || target == address(gateway)) revert BadTarget();

        Context memory prevContext = context;
        context = Context({l2Sender: l2Sender});
        bool success;
        assembly {
            success := call(gas(), target, 0, add(message, 0x20), mload(message), 0, 0) // call with 0 value. Don't copy returndata.
        }
        context = prevContext;

        if (success) {
            successfulMessages[messageId] = true;
        } else {
            failedMessages[messageId] = true;
        }
    }

    function getSender() external view returns (address) {
        return context.l2Sender;
    }
}
