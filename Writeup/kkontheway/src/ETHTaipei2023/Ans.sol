// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WBC} from "../../src/ETHTaipei2023/WBC/WBC.sol";

contract Ans {
    WBC public immutable wbc;

    constructor(address wbc_) {
        wbc = WBC(wbc_);
        wbc.bodyCheck();
    }

    function win() external {
        wbc.ready();
    }

    function judge() external view returns (address) {
        return block.coinbase;
    }

    function steal() external pure returns (uint160) {
        return 507778882907781185490817896798523593512684789769;
    }

    function execute() external pure returns (bytes32) {
        string memory ans = "HitAndRun";
        return bytes32(uint256(uint80(bytes10(abi.encodePacked(uint8(bytes(ans).length), ans)))));
    }

    function shout() external view returns (string memory) {
        if (gasleft() >= 8797746687695915000) {
            return "I'm the best";
        } else {
            return "We are the champion!";
        }
    }
}
