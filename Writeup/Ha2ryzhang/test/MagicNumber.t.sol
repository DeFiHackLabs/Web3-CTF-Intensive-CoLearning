pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/core/Ethernaut.sol";
import "../src/ethernaut/18-MagicNumber/MagicNumber.sol";
import "../src/ethernaut/18-MagicNumber/MagicNumberFactory.sol";

contract MagicNumberTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        MagicNumFactory factory = new MagicNumFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(factory);

        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";

        address addr;
        assembly {
            // create(value, offset, size)
            addr := create(0, add(bytecode, 0x20), 0x13)
        }
        
        MagicNum magicNumber = MagicNum(levelAddress);
        magicNumber.setSolver(addr);

        

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
