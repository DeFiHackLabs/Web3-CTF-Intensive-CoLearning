// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface ISimpleBank {
    function withdraw(bytes32, uint8, bytes32, bytes32) external payable;
}
