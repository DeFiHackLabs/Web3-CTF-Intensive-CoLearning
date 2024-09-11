// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {TransparentProxy} from "./TransparentProxy.sol";
import {AuthorizerUpgradeable} from "./AuthorizerUpgradeable.sol";

contract AuthorizerFactory {
    function deployWithProxy(address[] memory wards, address[] memory aims, address upgrader)
        external
        returns (address authorizer)
    {
        authorizer = address(
            new TransparentProxy( // proxy
                address(new AuthorizerUpgradeable()), // implementation
                abi.encodeCall(AuthorizerUpgradeable.init, (wards, aims)) // init data
            )
        );
        assert(AuthorizerUpgradeable(authorizer).needsInit() == 0); // invariant
        TransparentProxy(payable(authorizer)).setUpgrader(upgrader);
    }
}
