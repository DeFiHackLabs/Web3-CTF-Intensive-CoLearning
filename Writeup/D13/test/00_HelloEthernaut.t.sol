// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
interface Instance {
    function authenticate(string memory passkey) external;
    function password() external view returns (string memory);
    function getCleared() external view returns (bool);
}

contract ContractTest00 is Test {
    function setUp() public {
    }

    function testExploit0() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("https://rpc.ankr.com/eth_sepolia"));
        
        Instance level0 = Instance(0x044dD753634CaAa34c6F051D5A245e82bB65E4Fd);
        level0.password();
        level0.authenticate(level0.password());
        level0.getCleared();
    }
}
