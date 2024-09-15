player 在 access 里，直接 mint 即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/utils/Context.sol";
import "./utils/BaseTest.sol";
import "./utils/Utilities.sol";
import "src/Challenge.sol";

contract TestSolver is BaseTest {
    Challenge private challenge;

    constructor() {
    }

    function setupChallenge() public {
        challenge = new Challenge(player);
    }

    function testSolve() public {
        setupChallenge();
        vm.startPrank(player, player);

        ET et = challenge.et();
        for (uint256 i = 0; i < 20; i++) {
            et.mint(player, i);
        }
        challenge.solve();
        assertTrue(challenge.isSolved(), "Not solved.");
        vm.stopPrank();
    }
}
```



