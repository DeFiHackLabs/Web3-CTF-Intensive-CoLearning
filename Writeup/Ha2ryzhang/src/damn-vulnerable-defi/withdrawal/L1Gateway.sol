// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";

contract L1Gateway is OwnableRoles {
    uint256 public constant DELAY = 7 days;
    uint256 public constant OPERATOR_ROLE = _ROLE_0;

    bytes32 public root;
    uint256 public counter;
    address public xSender = address(0xBADBEEF);
    mapping(bytes32 id => bool finalized) public finalizedWithdrawals;

    error BadNewRoot();
    error EarlyWithdrawal();
    error InvalidProof();
    error AlreadyFinalized(bytes32 leaf);

    event ValidProof(bytes32[] proof, bytes32 root, bytes32 leaf);
    event FinalizedWithdrawal(bytes32 leaf, bool success, bool isOperator);

    constructor() {
        _initializeOwner(msg.sender);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        if (_root == bytes32(0) || _root == root) revert BadNewRoot();
        root = _root;
    }

    function finalizeWithdrawal(
        uint256 nonce,
        address l2Sender,
        address target,
        uint256 timestamp,
        bytes memory message,
        bytes32[] memory proof
    ) external {
        if (timestamp + DELAY > block.timestamp) revert EarlyWithdrawal();

        bytes32 leaf = keccak256(abi.encode(nonce, l2Sender, target, timestamp, message));

        // Only allow trusted operators to finalize without proof
        bool isOperator = hasAnyRole(msg.sender, OPERATOR_ROLE);
        if (!isOperator) {
            if (MerkleProof.verify(proof, root, leaf)) {
                emit ValidProof(proof, root, leaf);
            } else {
                revert InvalidProof();
            }
        }

        if (finalizedWithdrawals[leaf]) revert AlreadyFinalized(leaf);

        // state changes before external call
        finalizedWithdrawals[leaf] = true;
        counter++;

        xSender = l2Sender;
        bool success;
        assembly {
            success := call(gas(), target, 0, add(message, 0x20), mload(message), 0, 0) // call with 0 value. Don't copy returndata.
        }
        xSender = address(0xBADBEEF);

        emit FinalizedWithdrawal(leaf, success, isOperator);
    }
}
