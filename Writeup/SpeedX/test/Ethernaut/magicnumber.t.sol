pragma solidity ^0.8.0;

import "Ethernaut/magicnumber_poc.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagicNumberTest is Test
{
  MagicNumberPoc magicNumberPoc;
  MagicNum magicNumber;

  function setUp() public 
  {
    magicNumber = new MagicNum();
    magicNumberPoc = new MagicNumberPoc(address(magicNumber));
  }

  function testMagicNumber() public 
  {
    uint256 solverSize = getCodeSize(magicNumber.solver());
    magicNumberPoc.exploit();

    console.log(solverSize);
    assertTrue(solverSize < 10, "solver size should < 10");
  }

  function getCodeSize(address _addr) public view returns (uint size) {
    assembly {
      size := extcodesize(_addr)
    }
  }
}