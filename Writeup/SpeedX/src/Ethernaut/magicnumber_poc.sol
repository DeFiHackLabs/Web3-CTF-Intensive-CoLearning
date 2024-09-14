pragma solidity ^0.8.0;


import "Ethernaut/magicnumber.sol";

contract MagicNumberPoc 
{
  MagicNumber magicNumber;
  constructor(_magicNumber)
  {
    magicNumber = MagicNumber(_magicNumber);
  }

  function exploit() public 
  {
    solver = new Solver();
    magicNumber.setSolver(solver);
  }
}

contract Solver 
{
  function whatIsTheMeaningOfLife() public returns(bytes32)
  {

  }
}