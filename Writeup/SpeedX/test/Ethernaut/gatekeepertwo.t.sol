// npx hardhat test test/Ethernaut/gatekeepertwo.t.sol

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "Ethernaut/gatekeepertwo_poc.sol";
import "forge-std/console.sol";

contract GatekeeperTwoTest is Test {  
  GatekeeperTwoPoc gatekeeperTwoPoc;
  GatekeeperTwo gatekeeperTwo;

  function setUp() public {
    gatekeeperTwo = new GatekeeperTwo();
  }

  function testExploit() public {
    gatekeeperTwoPoc = new GatekeeperTwoPoc(address(gatekeeperTwo));

    assertEq(gatekeeperTwo.entrant(), tx.origin);
  }
} 