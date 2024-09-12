pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import  "Ethernaut/preservation_poc.sol";
import "forge-std/console.sol";

contract PreservationTest is Test 
{
  Preservation preservation;
  PreservationPoc preservationPoc;
  LibraryContract timeZone1Library;
  LibraryContract timeZone2Library;

  function setUp() public 
  {
    timeZone1Library = new LibraryContract();
    timeZone2Library = new LibraryContract();

    preservation = new Preservation(address(timeZone1Library), address(timeZone2Library));
    preservationPoc = new PreservationPoc(address(preservation));
  }

  function testOwner() public 
  {
    console.log(preservation.owner(), address(this));
    assertEq(preservation.owner(), address(this));
    address newOwner = 0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B;
    preservationPoc.exploit(newOwner);
    assertEq(preservation.owner(), newOwner);
    // assertEq(address(timeZone1Library), preservation.timeZone1Library.address);
  }
}