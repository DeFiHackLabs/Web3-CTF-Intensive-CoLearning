pragma solidity ^0.8.0;


import "Ethernaut/magicnumber.sol";

contract MagicNumberPoc 
{
  MagicNum magicNumber;
  constructor(address _magicNumber)
  {
    magicNumber = MagicNum(_magicNumber);
  }

  function exploit() public 
  {
    address solver = deployMinimalMeaningOfLife();
    magicNumber.setSolver(solver);
  }

  function deployMinimalMeaningOfLife() public returns (address) {
    bytes memory bytecode = hex"600a600c600039600a6000f3602a60505260206050f3";
    address addr;
    assembly {
        addr := create(0, add(bytecode, 0x20), mload(bytecode))
    }
    return addr;
  }
}