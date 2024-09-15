
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "Ethernaut/shop_poc.sol";

contract ShopPocScript is Script
{
  function run() public
  {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerKey);

    ShopPoc shopPoc = ShopPoc(0xd56A28610b5a592ec887aa23F65CD67a856f1aB6);
    shopPoc.exploit();

    vm.stopBroadcast();
  }
}