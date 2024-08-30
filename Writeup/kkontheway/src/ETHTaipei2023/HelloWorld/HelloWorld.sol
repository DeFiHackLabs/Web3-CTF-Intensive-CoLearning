// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Hello World!

import {Base} from "../Base.sol";

contract HelloWorld {
    bytes32 private immutable _answer;

    bool public success;

    constructor() {
        _answer = keccak256(abi.encodePacked("HelloWorld"));
    }

    function answer(string calldata data) external {
        bytes32 hash = keccak256(abi.encodePacked(data));
        if (hash == _answer) {
            success = true;
        }
    }
}

contract HelloWorldBase is Base {
    HelloWorld public helloWorld;

    constructor(uint256 startTime, uint256 endTime, uint256 fullScore) Base(startTime, endTime, fullScore) {}

    function setup() external override {
        helloWorld = new HelloWorld();
    }

    function solve() public override {
        require(helloWorld.success());
        super.solve();
    }
}
