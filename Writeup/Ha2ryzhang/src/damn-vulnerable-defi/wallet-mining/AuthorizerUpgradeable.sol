// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

contract AuthorizerUpgradeable {
    uint256 public needsInit = 1;
    mapping(address => mapping(address => uint256)) private wards;

    event Rely(address indexed usr, address aim);

    constructor() {
        needsInit = 0; // freeze implementation
    }

    function init(address[] memory _wards, address[] memory _aims) external {
        require(needsInit != 0, "cannot init");
        for (uint256 i = 0; i < _wards.length; i++) {
            _rely(_wards[i], _aims[i]);
        }
        needsInit = 0;
    }

    function _rely(address usr, address aim) private {
        wards[usr][aim] = 1;
        emit Rely(usr, aim);
    }

    function can(address usr, address aim) external view returns (bool) {
        return wards[usr][aim] == 1;
    }
}
