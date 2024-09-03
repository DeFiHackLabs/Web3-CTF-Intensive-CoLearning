// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/Ethernaut/hello_ethernaut.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract HelloEthernautScript is Script {
    Instance public instance =
        Instance(0x820d44A2D9F749b79fC81A0943945cCF93f00C11);

    function run() external {
        string memory password = instance.password();
        console.log("Password: ", password);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        instance.authenticate(password);
        vm.stopBroadcast();
    }
}
