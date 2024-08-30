// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEthernaut {
    function createLevelInstance(address) external payable; // Add `payable` due to 17-Recovery requirement.
    function submitLevelInstance(address payable) external;
}