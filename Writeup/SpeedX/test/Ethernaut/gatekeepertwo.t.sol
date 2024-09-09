// npx hardhat test test/Ethernaut/gatekeepertwo.t.sol

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "Ethernaut/gatekeepertwo.sol";
import "forge-std/console.sol";

contract GatekeeperTwoTest is Test {  
  GatekeeperTwo gatekeeperTwo;

  function setUp() public {
    // gatekeeperTwo = new GatekeeperTwo();
  }

  function testExploit() public {
    uint64 _gateKey = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ type(uint64).max;
    console.log("gateKey", _gateKey);
  }
} 