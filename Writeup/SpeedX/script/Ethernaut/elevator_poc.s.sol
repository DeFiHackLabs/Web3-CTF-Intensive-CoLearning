//
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "Ethernaut/elevator_poc.sol";

contract ElevatorPocScript is Script {
    function run() public {
      uint256 deployerKey = vm.envUint("PRIVATE_KEY");
      vm.startBroadcast(deployerKey);

      ElevatorPoc poc = new ElevatorPoc(0xC4cD0B8A5F633EEFDd855816B436eed2596e94B9);
      poc.exploit();

      vm.stopBroadcast();
    }
}