pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import  "Ethernaut/preservation.sol";
import "forge-std/console.sol";

contract PreservationTest is Test 
{
  Preservation preservation;
  LibraryContract timeZone1Library;
  LibraryContract timeZone2Library;

  function setUp() public 
  {
    timeZone1Library = new LibraryContract();
    timeZone2Library = new LibraryContract();

    preservation = new Preservation(address(timeZone1Library), address(timeZone2Library));
  }

  function testOwner() public 
  {
      // preservation.setFirstTime(1);
      console.log("xxx", preservation.timeZone1Library.address);
      console.log(address(timeZone2Library));

      assertEq(address(timeZone1Library), preservation.timeZone1Library.address);
  }
}