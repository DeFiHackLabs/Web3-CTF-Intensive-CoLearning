//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomToken {
    address public l1Token;
    constructor(address _l1Token) {
        l1Token = _l1Token;
    }

    function mint(address to, uint256 amount) external {}

    function burn(address to, uint256 amount) external {}
}
