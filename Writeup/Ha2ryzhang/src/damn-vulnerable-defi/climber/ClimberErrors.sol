// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

error CallerNotTimelock();
error NewDelayAboveMax();
error NotReadyForExecution(bytes32 operationId);
error InvalidTargetsCount();
error InvalidDataElementsCount();
error InvalidValuesCount();
error OperationAlreadyKnown(bytes32 operationId);
error CallerNotSweeper();
error InvalidWithdrawalAmount();
error InvalidWithdrawalTime();
